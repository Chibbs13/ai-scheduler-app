import Flutter
import EventKit

public class CalendarPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "calendar_plugin", binaryMessenger: registrar.messenger())
        let instance = CalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private let eventStore = EKEventStore()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestPermission(result: result)
        case "addEvent":
            addEvent(call: call, result: result)
        case "updateEvent":
            updateEvent(call: call, result: result)
        case "deleteEvent":
            deleteEvent(call: call, result: result)
        case "getEvents":
            getEvents(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
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
    }
    
    private func addEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    }
    
    private func updateEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    }
    
    private func deleteEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    }
    
    private func getEvents(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    }
} 