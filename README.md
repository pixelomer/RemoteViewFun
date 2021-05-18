# Making a UIView Service

This is an article about how I made my own UIView service **on iOS 13.4.1**. By the time you read this, this article might be out of date. This article contains both my successful and failed attempts. **This is not a step-by-step guide.**

## Definitions

**UIView Service:** A process on iOS that serves remote view controllers.

**Remote View Controllers:** A remote view controller (`_UIRemoteViewController`) represents a view controller that is displayed on your process while actually being located in a UIView service. This is a private API that was introduced with iOS 6 and its main purpose is to prevent user applications from having access to private data. For example, when you create an `MFMailComposeViewController`, you are actually creating a remote view controller. The view is still displayed in your own application, but the view controller object is not available in your application. This means that you cannot directly extract private information from that view controller, such as the user's email address.

**Remote Views:** Remote views (`_UIRemoteView`) are the view objects inside of remote view controllers. We don't really need to think about these.

**iOS Tweak:** This is a term used by people who jailbreak iOS devices. An iOS tweak is a shared library that is loaded into other processes by a process such as Cydia Substrate's `substrated`. These libraries are used to customize the behavior of a lot of things by using Objective-C runtime functions to modify the implementations of methods. This is a term that is not related to remote view controllers.

## Introduction

Recently, I wanted to use remote view controllers in my iOS tweak. I knew about these view controllers thanks to [an article by Ole Begemann](https://oleb.net/blog/2012/10/remote-view-controllers-in-ios-6/). You should read it too if you haven't read it.

At first, I assumed making my own UIView service would've been an easy task. These view controllers have existed since iOS 6, so there has to be some examples and articles online, right? Nope. That article I linked is apparently the only public article about remote view controllers. So, I decided to research them further.

## Looking at different UIView services

I started by looking at different UIView services located inside of `/Applications`. Specifically, I looked at `MusicUIService.app`, `PassbookUIService.app` and `MailCompositionService.app`. These are all built-in remote view services that come with iOS and they have multiple things in common as expected.

**Shared Info.plist values**  
```xml
<key>CanInheritApplicationStateFromOtherProcesses</key>
<true/>
<key>UIViewServiceUsesNSXPCConnection</key>
<true/>
<key>SBAppTags</key>
<array>
  <string>hidden</string>
</array>
<key>SBMachServices</key>
<array>
  <string>com.apple.uikit.viewservice.[bundle identifier]</string>
</array>
```

**Shared entitlements**  
```xml
<key>com.apple.UIKit.vends-view-services</key>
<true/>
```

## First attempt

With the help of Ole Begemann's article from 2012, I could now try making my own remote view service. I started by creating two Theos projects: one for the view service and one for the client. The view service didn't have anything special, it just had a view controller named `SERVRootViewController` and the necessary Info.plist values and entitlements shown above. As for the client, it used the `_UIRemoteViewController` class to create a new remote view controller.

```objc
[_UIRemoteViewController
  requestViewController:@"SERVRootViewController"
  fromServiceWithBundleIdentifier:@"com.pixelomer.testservice"
  connectionHandler:^(_UIRemoteViewController *vc, NSError *err){
    void(^blockForMain)(void) = ^{
      if (vc) [self presentViewController:vc animated:YES completion:nil];
      else {
        UIAlertController *alert = [UIAlertController
          alertControllerWithTitle:@"Error"
          message:err.description
          preferredStyle:UIAlertControllerStyleAlert
        ];
        [self presentViewController:alert animated:YES completion:nil];
      }
    };
    if ([NSThread isMainThread]) blockForMain();
    else dispatch_async(dispatch_get_main_queue(), blockForMain);
  }
];
```

Unfortunately, this did not work. I got the following error instead of a remote view controller.
```
_UIViewServiceInterfaceErrorDomain (error code 0)
Un-trusted clients may not open applications in the background.
```
This probably meant that I was missing an entitlement or Info.plist value that made my client "trusted". However, instead of finding that magic value, I ended up using the SpringBoard as a client rather than my own app. To do this, I created a SpringBoard tweak which had the same code.

After installing the tweak and reloading SpringBoard, the service application was actually launched! However, I still couldn't get a remote view controller.
```
_UIViewServiceInterfaceErrorDomain (error code 2)
Attempt to aquire assertions for com.pixelomer.testservice failed
```

## A dive into the headers

When I first saw the error seen above, I was stuck for a while. After desperately trying different things, I decided to go back to the headers, specifically [\_UIRemoteViewController.h](https://developer.limneos.net/?ios=13.1.3&framework=UIKitCore.framework&header=_UIRemoteViewController.h). In this case, instance methods were irrelevant since I didn't have an instance to begin with.
```objc
+(id)exportedInterface;
+(BOOL)_shouldSendLegacyMethodsFromViewWillTransitionToSize;
+(BOOL)_shouldForwardViewWillTransitionToSize;
+(id)serviceViewControllerInterface;
+(id)requestViewControllerWithService:(id)arg1 connectionHandler:(/*^block*/id)arg2 ;
+(id)requestViewController:(id)arg1 fromServiceWithBundleIdentifier:(id)arg2 connectionHandler:(/*^block*/id)arg3 ;
+(BOOL)__shouldHostRemoteTextEffectsWindow;
+(id)_requestViewController:(id)arg1 traitCollection:(id)arg2 fromServiceWithBundleIdentifier:(id)arg3 service:(id)arg4 connectionHandler:(/*^block*/id)arg5 ;
+(BOOL)shouldPropagateAppearanceCustomizations;
+(BOOL)__shouldAllowHostProcessToTakeFocus;
+(id)requestViewController:(id)arg1 traitCollection:(id)arg2 fromServiceWithBundleIdentifier:(id)arg3 connectionHandler:(/*^block*/id)arg4 ;
+(id)requestViewControllerWithService:(id)arg1 traitCollection:(id)arg2 connectionHandler:(/*^block*/id)arg3 ;
```

From the methods above, only two methods looked interesting: `+exportedInterface` and `+serviceViewControllerInterface`. I tried calling these methods using [FLEX](https://github.com/Flipboard/FLEX). `_UIRemoteViewController` returned null for these methods but when I tried calling them in `MFMailComposeRemoteViewController` (a subclass of `_UIRemoteViewController`), they returned two separate instances of `NSXPCInterface` with two different protocols. Investigating these protocols revealed that the protocol returned by `+exportedInterface` contained some methods of the client while the protocol returned by `+serviceViewControllerInterface` contained some methods of the server. These objects seemed like "header" objects.

With this new information, I subclassed `_UIRemoteViewController` to override these methods.
```objc
// NSXPCInterface is public API, yet the headers don't have it...
@interface NSXPCInterface : NSObject
+ (instancetype)interfaceWithProtocol:(Protocol *)protocol;
@end

// Service
@protocol SERVRootViewControllerRemoteService
- (instancetype)init;
@end

// Client
@protocol SERVRootViewControllerRemoteHost
@end

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
```

This still didn't work. However, this time I got a different error about an interrupted connection. Progress!

## Checking out MailCompositionService

MailCompositionService is an application that hosts the content for `MFMailComposeViewController`. I copied this app to my computer for disassembly. It's a small binary and decompilation took a few seconds. Apparently, a class-dump would've been enough though. While looking at the methods, I immediately noticed `+_exportedInterface` and `+_remoteViewControllerInterface`.

![Ghidra Screenshot](images/ghidra.png)

These methods seemed very similar to the methods on the client. I implemented these methods in `SERVRootViewController`.

```objc
+ (NSXPCInterface *)_exportedInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteService)];
}

+ (NSXPCInterface *)_remoteViewControllerInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteHost)];
}
```

After recompiling and installing the service, it finally worked! The remote view controller was being shown in SpringBoard.

## One more thing - Calling methods on the remote view controller

While looking at the headers, I found one more thing. It seems like `_UIRemoteViewController` has a method named `-serviceViewControllerProxy`. You can use this object to call methods on the remote object.
```objc
@protocol SERVRootViewControllerRemoteService
-(instancetype)init;
-(void)myMethod:(NSString*)arg1;
@end

/* ... */

[vc.serviceViewControllerProxy performSelector:@selector(myMethod:) withObject:@"Testing"];
```

The return value of the methods you call using this proxy must return either `void` or `NSProgress *`. Any other type will cause an exception to be raised.

**Warning:** This only works on iOS 7.0 and higher. iOS 6 seems to rely on other things for communication between processes and it doesn't have this method.