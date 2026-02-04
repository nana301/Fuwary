import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
import TanumarusenseiController from "./tanumarusensei_controller"
application.register("tanumarusensei", TanumarusenseiController)
