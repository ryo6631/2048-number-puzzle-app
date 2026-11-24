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
        CAPPluginMethod(name: "showLeaderboard", returnType: CAPPluginReturnPromise)
    ]

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

    @objc func showLeaderboard(_ call: CAPPluginCall) {
        let leaderboardId = call.getString("leaderboardId")
        guard GKLocalPlayer.local.isAuthenticated else {
            // 未サインイン時はリーダーボードを開かず、認証画面の表示だけ試みる
            let localPlayer = GKLocalPlayer.local
            localPlayer.authenticateHandler = { viewController, error in
                if let vc = viewController {
                    DispatchQueue.main.async {
                        self.bridge?.viewController?.present(vc, animated: true, completion: nil)
                    }
                }
            }
            call.resolve(["presented": false, "reason": "notAuthenticated"])
            return
        }
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

    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
