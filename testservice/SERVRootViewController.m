#import "SERVRootViewController.h"

@implementation SERVRootViewController

- (instancetype)init {
	NSLog(@"[TestService] -init called.");
	return [super init];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor redColor];
}

+ (NSXPCInterface *)_exportedInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteService)];
}

+ (NSXPCInterface *)_remoteViewControllerInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteHost)];
}

@end
