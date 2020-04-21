#import <UIKit/UIKit.h>

@interface SERVRootViewController : UIViewController {
	UILabel *_testLabel;
	NSTimer *_labelTimer;
	NSUInteger _colorIndex;
	NSString *_text;
}
- (void)setText:(NSString *)text;
@end
