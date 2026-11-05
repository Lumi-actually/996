framework = framework or {}

framework.PACKAGE_NAME      = "framework"
framework.FRAMEWORK_NAME    = 'mmoclient mvc'

framework.Facade            = require( framework.PACKAGE_NAME .. '/patterns/facade/Facade')
framework.Mediator          = require( framework.PACKAGE_NAME .. '/patterns/mediator/Mediator')
framework.Proxy             = require( framework.PACKAGE_NAME .. '/patterns/proxy/Proxy')
framework.SimpleCommand     = require( framework.PACKAGE_NAME .. '/patterns/command/SimpleCommand')
framework.MacroCommand      = require( framework.PACKAGE_NAME .. '/patterns/command/MacroCommand')
framework.Notifier          = require( framework.PACKAGE_NAME .. '/patterns/observer/Notifier')
framework.Notification      = require( framework.PACKAGE_NAME .. '/patterns/observer/Notification')


