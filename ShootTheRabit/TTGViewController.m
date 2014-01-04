//
//  TTGViewController.m
//  ShootTheRabit
//
//  Created by Jim on 12/27/13.
//  Copyright (c) 2013 TangoTiger. All rights reserved.
//

#import "TTGViewController.h"
#import "TTGMyScene.h"
@interface TTGViewController()
@property (nonatomic) TTGMyScene *mainScene;
@end


@implementation TTGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    /*
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    
    // Create and configure the scene.
    SKScene * scene = [TTGMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
     */
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
        
    // Create and configure the scene.
    _mainScene = [TTGMyScene sceneWithSize:skView.bounds.size];
    _mainScene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:_mainScene];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

/*
-(BOOL) canBecomeFirstResponder
{
    return YES;
}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"motion begins %@", event);
    if (motion == UIEventSubtypeMotionShake )         // shaking has began.
    {
        NSLog(@"Shake begins!");
    }
}


-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"motion ends");
    if (motion == UIEventSubtypeMotionShake )
    {
        [self.mainScene ShakeGesture];
    }
}
 */


@end
