#import "CalendarPlugin.h"
#import <Flutter/Flutter.h>

@implementation CalendarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"calendar_plugin"
                                  binaryMessenger:[registrar messenger]];
  CalendarPlugin *instance = [[CalendarPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}
@end