import Foundation
import Capacitor
import GameKit

@objc(GameCenterPlugin)
public class GameCenterPlugin: CAPPlugin, CAPBridgedPlugin, GKGameCenterControllerDelegate {
    public let identifier = "GameCenterPlugin"
    public let jsName = "GameCenter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signIn", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "submitScore", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showLeaderboard", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "haptic", returnType: CAPPluginReturnPromise)
    ]

    @objc func haptic(_ call: CAPPluginCall) {
        let style = call.getString("style") ?? "light"
        DispatchQueue.main.async {
            let generator: UIImpactFeedbackGenerator
            switch style {
            case "medium":
                generator = UIImpactFeedbackGenerator(style: .medium)
            case "heavy":
                generator = UIImpactFeedbackGenerator(style: .heavy)
            default:
                generator = UIImpactFeedbackGenerator(style: .light)
            }
            generator.impactOccurred()
        }
        call.resolve()
    }

    @objc func signIn(_ call: CAPPluginCall) {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let vc = viewController {
                DispatchQueue.main.async {
                    self.bridge?.viewController?.present(vc, animated: true, completion: nil)
                }
                call.resolve(["authenticated": false, "presented": true])
            } else if localPlayer.isAuthenticated {
                call.resolve([
                    "authenticated": true,
                    "playerName": localPlayer.displayName
                ])
            } else {
                var result: [String: Any] = ["authenticated": false]
                if let error = error {
                    result["error"] = error.localizedDescription
                }
                call.resolve(result)
            }
        }
    }

    @objc func submitScore(_ call: CAPPluginCall) {
        guard let leaderboardId = call.getString("leaderboardId"),
              let score = call.getInt("score") else {
            call.reject("leaderboardId and score are required")
            return
        }
        guard GKLocalPlayer.local.isAuthenticated else {
            call.resolve(["submitted": false, "reason": "notAuthenticated"])
            return
        }
        if #available(iOS 14.0, *) {
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardId]) { error in
                if let error = error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve(["submitted": true])
                }
            }
        } else {
            let gs = GKScore(leaderboardIdentifier: leaderboardId)
            gs.value = Int64(score)
            GKScore.report([gs]) { error in
                if let error = error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve(["submitted": true])
                }
            }
        }
    }

    private var lastAuthError: String?

    private func presentLeaderboard(leaderboardId: String?, call: CAPPluginCall) {
        DispatchQueue.main.async {
            let vc: GKGameCenterViewController
            if let leaderboardId = leaderboardId, #available(iOS 14.0, *) {
                vc = GKGameCenterViewController(leaderboardID: leaderboardId, playerScope: .global, timeScope: .allTime)
            } else {
                let fallback = GKGameCenterViewController()
                fallback.viewState = .leaderboards
                vc = fallback
            }
            vc.gameCenterDelegate = self
            self.bridge?.viewController?.present(vc, animated: true, completion: nil)
            call.resolve(["presented": true])
        }
    }

    @objc func showLeaderboard(_ call: CAPPluginCall) {
        let leaderboardId = call.getString("leaderboardId")
        let localPlayer = GKLocalPlayer.local
        if localPlayer.isAuthenticated {
            presentLeaderboard(leaderboardId: leaderboardId, call: call)
            return
        }
        // 未認証なら認証をやり直し、結果（成功／ログイン画面／エラー）を返す
        localPlayer.authenticateHandler = { viewController, error in
            if let error = error {
                self.lastAuthError = error.localizedDescription
            }
            if let vc = viewController {
                DispatchQueue.main.async {
                    self.bridge?.viewController?.present(vc, animated: true, completion: nil)
                }
                call.resolve(["presented": false, "reason": "authPrompt"])
            } else if localPlayer.isAuthenticated {
                self.presentLeaderboard(leaderboardId: leaderboardId, call: call)
            } else {
                var result: [String: Any] = ["presented": false, "reason": "notAuthenticated"]
                if let e = self.lastAuthError {
                    result["error"] = e
                }
                call.resolve(result)
            }
        }
    }

    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
