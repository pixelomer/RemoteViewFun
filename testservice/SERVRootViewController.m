#import "SERVRootViewController.h"

@implementation SERVRootViewController

static NSArray<NSArray<UIColor *> *> *_colors;

+ (void)load {
	if (self == [SERVRootViewController class]) {
		_colors = @[
			@[[UIColor redColor], [UIColor whiteColor]],
			@[[UIColor greenColor], [UIColor blackColor]],
			@[[UIColor blueColor], [UIColor whiteColor]]
		];
	}
}

- (instancetype)init {
	NSLog(@"[TestService] -init called.");
	return [super init];
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
	_colorIndex++;
	if (_colorIndex >= _colors.count) _colorIndex = 0;
	self.view.backgroundColor = _colors[_colorIndex][0];
	_testLabel.textColor = _colors[_colorIndex][1];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
		initWithTarget:self
		action:@selector(handleTap:)
	];
	[self.view addGestureRecognizer:tapRecognizer];
	_colorIndex = _colors.count;
	_testLabel = [UILabel new];
	_testLabel.text = _text;
	_testLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self handleTap:tapRecognizer];
	[self.view addSubview:_testLabel];
	[self.view addConstraints:@[
		[NSLayoutConstraint
			constraintWithItem:_testLabel
			attribute:NSLayoutAttributeCenterX
			relatedBy:NSLayoutRelationEqual
			toItem:_testLabel.superview
			attribute:NSLayoutAttributeCenterX
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_testLabel
			attribute:NSLayoutAttributeCenterY
			relatedBy:NSLayoutRelationEqual
			toItem:_testLabel.superview
			attribute:NSLayoutAttributeCenterY
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_testLabel
			attribute:NSLayoutAttributeWidth
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:nil
			attribute:NSLayoutAttributeNotAnAttribute
			multiplier:0.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_testLabel
			attribute:NSLayoutAttributeHeight
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:nil
			attribute:NSLayoutAttributeNotAnAttribute
			multiplier:0.0
			constant:0.0
		]
	]];
	_labelTimer = [NSTimer
		scheduledTimerWithTimeInterval:0.5
		target:self
		selector:@selector(timerTick:)
		userInfo:nil
		repeats:YES
	];
}

- (void)timerTick:(NSTimer *)timer {
	_testLabel.hidden = !_testLabel.hidden;
}

- (void)setText:(NSString *)text {
	_text = text;
	_testLabel.text = text;
}

+ (NSXPCInterface *)_exportedInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteService)];
}

+ (NSXPCInterface *)_remoteViewControllerInterface {
	return [NSXPCInterface interfaceWithProtocol:@protocol(SERVRootViewControllerRemoteHost)];
}

@end
