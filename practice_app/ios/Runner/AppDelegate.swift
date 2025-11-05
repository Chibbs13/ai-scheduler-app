import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "calendar_plugin", binaryMessenger: controller.binaryMessenger)
    
    let eventStore = EKEventStore()
    
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "requestPermission":
        eventStore.requestAccess(to: .event) { granted, error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "PERMISSION_ERROR",
                                message: error.localizedDescription,
                                details: nil))
              return
            }
            result(granted)
          }
        }
        
      case "addEvent":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let startDate = args["startDate"] as? Double,
              let endDate = args["endDate"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments for addEvent",
                            details: nil))
          return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date(timeIntervalSince1970: startDate / 1000)
        event.endDate = Date(timeIntervalSince1970: endDate / 1000)
        event.notes = args["notes"] as? String
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
          try eventStore.save(event, span: .thisEvent)
          result(event.eventIdentifier)
        } catch {
          result(FlutterError(code: "SAVE_ERROR",
                            message: error.localizedDescription,
                            details: nil))
        }
        
      case "updateEvent":
        guard let args = call.arguments as? [String: Any],
              let eventId = args["eventId"] as? String,
              let title = args["title"] as? String,
              let startDate = args["startDate"] as? Double,
              let endDate = args["endDate"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments for updateEvent",
                            details: nil))
          return
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
          result(FlutterError(code: "EVENT_NOT_FOUND",
                            message: "Event not found",
                            details: nil))
          return
        }
        
        event.title = title
        event.startDate = Date(timeIntervalSince1970: startDate / 1000)
        event.endDate = Date(timeIntervalSince1970: endDate / 1000)
        event.notes = args["notes"] as? String
        
        do {
          try eventStore.save(event, span: .thisEvent)
          result(true)
        } catch {
          result(FlutterError(code: "SAVE_ERROR",
                            message: error.localizedDescription,
                            details: nil))
        }
        
      case "deleteEvent":
        guard let args = call.arguments as? [String: Any],
              let eventId = args["eventId"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments for deleteEvent",
                            details: nil))
          return
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
          result(FlutterError(code: "EVENT_NOT_FOUND",
                            message: "Event not found",
                            details: nil))
          return
        }
        
        do {
          try eventStore.remove(event, span: .thisEvent)
          result(true)
        } catch {
          result(FlutterError(code: "DELETE_ERROR",
                            message: error.localizedDescription,
                            details: nil))
        }
        
      case "getEvents":
        guard let args = call.arguments as? [String: Any],
              let startDate = args["startDate"] as? Double,
              let endDate = args["endDate"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments for getEvents",
                            details: nil))
          return
        }
        
        let start = Date(timeIntervalSince1970: startDate / 1000)
        let end = Date(timeIntervalSince1970: endDate / 1000)
        
        let predicate = eventStore.predicateForEvents(withStart: start,
                                                    end: end,
                                                    calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        let eventList = events.map { event -> [String: Any] in
          return [
            "id": event.eventIdentifier,
            "title": event.title,
            "description": event.notes ?? "",
            "startDate": event.startDate.timeIntervalSince1970 * 1000,
            "endDate": event.endDate.timeIntervalSince1970 * 1000,
          ]
        }
        
        result(eventList)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
