//
//  WGLoginViewController.m
//  WizGroup
//
//  Created by wiz on 12-10-25.
//  Copyright (c) 2012年 cn.wiz. All rights reserved.
//

#import "WGLoginViewController.h"
#import "WizAccountManager.h"
#import "MBProgressHUD.h"
#import "WGNavigationBar.h"
#import "WGBarButtonItem.h"
#import "CommonString.h"
#import <QuartzCore/QuartzCore.h>
#import "WizSyncCenter.h"

@interface UIView (LoginPlaceHoder)
+ (UIView*) loginTextFieldView:(UIImage*)image frame:(CGRect)rect;
@end

@implementation UIView (LoginPlaceHoder)

+ (UIView*) loginTextFieldView:(UIImage*)image frame:(CGRect)rect
{
    UIView* view = [[UIView alloc] initWithFrame:rect];
    
    float imageWidth = 30;
    float imageHeight = imageWidth;
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake((rect.size.width - imageWidth)/2, (rect.size.height - imageHeight)/2, imageWidth, imageHeight)];
    imageView.image = image;
    [view addSubview:imageView];
    [imageView release];
    return [view autorelease];
}

@end

@interface WGLoginViewController () < UIGestureRecognizerDelegate, WizXmlVerifyAccountDelegate>
{
    UITextField* usernameTextField;
    UITextField* passwordTextField;
    UIButton* clientLoginButton;
    UIScrollView* backgroudView;
    
    UIView* inputBackgroudView;
}
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* password;
@end

@implementation WGLoginViewController
@synthesize userName;
@synthesize password;
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [inputBackgroudView release];
    [backgroudView release];
    [userName release];
    [password release];
    [usernameTextField release];
    [passwordTextField release];
    [clientLoginButton release];
    [super dealloc];
}
- (void) resignAllTextField
{
    [usernameTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        usernameTextField = [[UITextField alloc] init];
        usernameTextField.borderStyle = UITextBorderStyleNone;
        usernameTextField.placeholder = NSLocalizedString(@"Username", nil);
        usernameTextField.textAlignment = UITextAlignmentLeft;
        usernameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        usernameTextField.leftViewMode = UITextFieldViewModeAlways;
        usernameTextField.leftView = [UIView loginTextFieldView:[UIImage imageNamed:@"login_usernume"] frame:CGRectMake(0, 0, 60, 40)];

        
        passwordTextField = [[UITextField alloc] init];
        passwordTextField.secureTextEntry = YES;
        passwordTextField.borderStyle = UITextBorderStyleNone;
        passwordTextField.placeholder = NSLocalizedString(@"Password", nil);
        passwordTextField.textAlignment = UITextAlignmentLeft;
        passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passwordTextField.leftViewMode = UITextFieldViewModeAlways;
        passwordTextField.leftView = [UIView loginTextFieldView:[UIImage imageNamed:@"login_password"] frame:CGRectMake(0, 0, 60, 40)];
        //
        inputBackgroudView = [[UIView alloc] init];
        CALayer* layer = inputBackgroudView.layer;
        layer.borderColor = [UIColor lightGrayColor].CGColor;
        layer.borderWidth = 1.0f;
        layer.cornerRadius = 5.0f;
        //
        clientLoginButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        [clientLoginButton addTarget:self action:@selector(clientLogin) forControlEvents:UIControlEventTouchUpInside];
        [clientLoginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
        //
        backgroudView = [[UIScrollView alloc] init];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignAllTextField)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        tap.delegate = self;
        [backgroudView addGestureRecognizer:tap];
        [tap release];
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}
- (void) keyboardDidShow:(NSNotification*)nc
{
    NSDictionary* dic = [nc userInfo];
    CGRect rect = [[dic objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    backgroudView.frame = CGRectMake(0.0, 0.0,self.view.frame.size.width, self.view.frame.size.height - rect.size.height);
}

- (void) keyboardDidHide:(NSNotification*)nc
{
    backgroudView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
}


- (void) didVerifyAccountFaild:(std::string)accountUserId
{
   [MBProgressHUD hideAllHUDsForView:self.view animated:YES]; 
}

- (void) didVerifyAccountSucceed:(std::string)accountUserId
{
    [[WizAccountManager defaultManager] updateAccount:self.userName password:self.password];
    [[WizAccountManager defaultManager] registerActiveAccount:self.userName];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void) clientLogin
{
    [passwordTextField resignFirstResponder];
    [usernameTextField resignFirstResponder];
    //
    self.password = passwordTextField.text;
    self.userName = [usernameTextField.text lowercaseString];
    //
    NSString* error = WizStrError;
    if (self.password == nil|| [self.password length] == 0)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error message:WizStrPleaseenterpassword delegate:self cancelButtonTitle:WizStrOK otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	if (self.userName == nil || [self.userName length] == 0)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error message:WizStrPleaseenteuserid  delegate:self cancelButtonTitle:WizStrOK otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
    WizXmlVerifyAccountThread* verifyThread = [[[WizXmlVerifyAccountThread alloc] init] autorelease];
    verifyThread.accountPassword = WizNSStringToStdString(self.password);
    verifyThread.accountUserID = WizNSStringToCString(self.userName);
    
    verifyThread.delegate = self;
    [verifyThread start];
        MBProgressHUD* hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hub.labelText = NSLocalizedString(@"Login.....", nil);
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    backgroudView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    backgroudView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:backgroudView];
    //
    float startX = 10;
    float width = self.view.frame.size.width - 20;
    usernameTextField.frame = CGRectMake(0.0, 0.0, width, 40);
    passwordTextField.frame = CGRectMake(0.0, 40, width, 40);
    //
    
    UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 39.5, width, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [inputBackgroudView addSubview:lineView];
    [lineView release];
    [inputBackgroudView addSubview:usernameTextField];
    [inputBackgroudView addSubview:passwordTextField];
    //
    inputBackgroudView.frame = CGRectMake(startX, 40, width, 80);
    [backgroudView addSubview:inputBackgroudView];
    
    clientLoginButton.frame = CGRectMake(startX, 140, width, 40);
    [clientLoginButton setBackgroundImage:[UIImage imageNamed:@"login_button_ackgroud"] forState:UIControlStateNormal];
    clientLoginButton.titleLabel.textColor = [UIColor whiteColor];
    [backgroudView addSubview:clientLoginButton];
    //
    UIBarButtonItem* backItem = [WGBarButtonItem barButtonItemWithImage:[UIImage imageNamed:@"login_back"] hightedImage:nil target:self selector:@selector(backToHome)];
    self.navigationItem.leftBarButtonItem = backItem;
	// Do any additional setup after loading the view.
}
- (void) backToHome
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our control subview is on-screen
    if (clientLoginButton.superview != nil) {
        if ([touch.view isDescendantOfView:clientLoginButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
@end