#import <UIKit/UIKit.h>
#import "../Headers.h"

@interface SERVRemoteRootViewController : _UIRemoteViewController
+ (NSInvocation *)requestViewControllerWithConnectionHandler:(void(^)(SERVRemoteRootViewController *, NSError *))block;
@end

%subclass SERVRemoteRootViewController : _UIRemoteViewController

%new
+ (NSInvocation *)requestViewControllerWithConnectionHandler:(void(^)(SERVRemoteRootViewController *, NSError *))block {
	return [self
		requestViewController:@"SERVRootViewController"
		fromServiceWithBundleIdentifier:@"com.pixelomer.testservice"
		connectionHandler:(void(^)(id,id))block
	];
}

+ (NSXPCInterface *)exportedInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteHost)];
}

+ (NSXPCInterface *)serviceViewControllerInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteService)];
}

%end

static UIWindow *window;
static UIViewController *_vc;

%ctor {
  // Using dispatch_after() for this is a hack. Use something better for production
  // code, like hooking -[SpringBoard applicationDidFinishLaunching:].
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*10), dispatch_get_main_queue(), ^{
    [%c(SERVRemoteRootViewController)
      requestViewControllerWithConnectionHandler:^(_UIRemoteViewController *vc, NSError *err){
        void(^blockForMain)(void) = ^{
          _vc = vc;
          window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
          window.windowLevel = CGFLOAT_MAX/2.0;
          if (vc) {
            window.rootViewController = vc;
            [window makeKeyAndVisible];
            NSLog(@"VC: %@", vc);
          }
          else {
            window.rootViewController = [UIViewController new];
            [window makeKeyAndVisible];
            UIAlertController *alert = [UIAlertController
              alertControllerWithTitle:@"Error"
              message:err.description
              preferredStyle:UIAlertControllerStyleAlert
            ];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
          }
        };
        if ([NSThread isMainThread]) blockForMain();
        else dispatch_async(dispatch_get_main_queue(), blockForMain);
      }
    ];
  });
}