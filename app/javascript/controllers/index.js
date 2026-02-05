console.log("✅ controllers/index.js loaded")
import { application } from "./application"

import TurboFadeController from "./turbo_fade_controller"
import TanumarusenseiController from "./tanumarusensei_controller"
console.log("TurboFadeController", TurboFadeController)
console.log("TanumarusenseiController", TanumarusenseiController)

application.register("turbo-fade", TurboFadeController)
application.register("tanumarusensei", TanumarusenseiController)
