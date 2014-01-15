//
//  TTGMyScene.m
//  ShootTheRabit
//
//  Created by Jim on 12/27/13.
//  Copyright (c) 2013 TangoTiger. All rights reserved.
//

#import "TTGMyScene.h"

#define kScoreHudName @"scoreHud"
#define kHeroPosName @"heroPos"
#define kDebugOverlayNode @"debugOverlayName"
#define kHeroBulletNode @"heroBulletNode"
#define kHeroWalkSpeed 60  // higher number, faster move

// copied from 'Adventure'
#define kHeroProjectileSpeed 220.0
#define kHeroProjectileLifetime 1.1
//#define kHeroProjectileFadeOutTime 0.5
#define kBulletFadeOutTime 4.0

const int kNumberOfHeroWalkingImages = 3;
const int kNumberOfHeroFiringImages = 2;

@interface TTGMyScene()
@property (nonatomic) SKSpriteNode *hero;
@property (nonatomic) SKSpriteNode *world;
@property (nonatomic) SKSpriteNode *projectile;
@property (nonatomic) NSMutableArray *heroWalkFrames;
@property (nonatomic) NSMutableArray *heroFireFrames;
@end

@implementation TTGMyScene

NSString * const kBackgroudImageName = @"grassField4096";

//CGRect screenRect;
CGFloat screenHeight;
CGFloat screenWidth;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        screenWidth = size.width;
        screenHeight = size.height;
//        NSLog(@"screenWidth: %.0f  screenHeight: %.0f", screenWidth, screenHeight);
      
        self.anchorPoint = CGPointMake(0.5, 0.5);  // set anchor to Center of scene
        
        _world = [SKSpriteNode spriteNodeWithImageNamed:kBackgroudImageName];
        [self addChild:_world];
        
        _heroWalkFrames = [NSMutableArray new];
        _heroFireFrames = [NSMutableArray new];
        
        SKTextureAtlas *heroAtlas = [SKTextureAtlas atlasNamed:@"hero"];
        
        for (int i = 0; i < kNumberOfHeroFiringImages; i++) {
            NSString *textureName = [NSString stringWithFormat:@"heroFire%02d", i + 1];  //use 'i + 1', since images start with '1'
            SKTexture *temp = [heroAtlas textureNamed:textureName];
            [_heroFireFrames addObject:temp];
        }

        for (int i = 0; i < kNumberOfHeroWalkingImages; i++) {
            NSString *textureName = [NSString stringWithFormat:@"heroWalk%02d", i + 1];  //use 'i + 1', since images start with '1'
            SKTexture *temp = [heroAtlas textureNamed:textureName];
            [_heroWalkFrames addObject:temp];
        }

        
        [SKTexture preloadTextures:_heroFireFrames withCompletionHandler:^(void ) {}];
        [SKTexture preloadTextures:_heroWalkFrames withCompletionHandler:^(void){
            [self createHero];  //preload image, else hero "flashes white" when first starting to move
        }];
        
        _projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
        _projectile.xScale = 0.5;
        _projectile.yScale = 0.5;
        
        [self setupHud];
    }
    return self;
}

- (void) createHero {
    SKTexture *heroStand = [SKTexture textureWithImageNamed:@"heroStand"];
    _hero = [SKSpriteNode spriteNodeWithTexture:heroStand];
    
    _hero.position = CGPointMake(250, 150);
    _hero.name = @"hero";
    [_world addChild:_hero];    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    CGPoint newLocation = [[touches anyObject] locationInNode:self.world];
//    [self moveHeroToPoint:newLocation];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2 ){
            [self HeroFireGun];
        }
        else {
            CGPoint newLocation = [[touches anyObject] locationInNode:self.world];
            
            [self moveHeroToPoint:newLocation];
        }
    }
}

-(void) setupHud {
    CGFloat hudX = 0;
//    CGFloat hudY = self.frame.size.height - 60;
    CGFloat hudY = (self.frame.size.height / 2) - 30;
    
    SKNode *hud = [[SKNode alloc] init];
    hud.name = @"debugHud";

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
    label.name = kDebugOverlayNode;
    label.text = @"NO PLAYER";
    label.fontColor = [SKColor redColor];
    label.fontSize = 12;
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    label.position = CGPointMake(hudX, hudY);

//    [hud addChild:label];

  
    hud.position = CGPointMake(hudX, hudY);
    
//    [self addChild:hud];
    [self addChild:label];
/*
    CGPoint hudPos = hud.position;
    CGPoint dd = hud.position;
    float aaa = hud.frame.size.width;
    float hhh = hud.frame.size.height;
  */
}

-(void)setupHudOLD {
    SKLabelNode* scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    int margin = 10;
    scoreLabel.name = kScoreHudName;
    scoreLabel.fontSize = 15;
    scoreLabel.fontColor = [SKColor greenColor];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %02u", 0];
//    scoreLabel.position = CGPointMake(20 + scoreLabel.frame.size.width/2, self.size.height - (20 + scoreLabel.frame.size.height/2));
    scoreLabel.position = CGPointMake(margin + scoreLabel.frame.size.width/2, screenHeight - (margin + scoreLabel.frame.size.height/2));
//    NSLog(@"label.pos.x: %f   pos.y: %f", scoreLabel.position.x, scoreLabel.position.y);
    
    [self addChild:scoreLabel];
    
    SKLabelNode* healthLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    healthLabel.name = kHeroPosName;
    healthLabel.fontSize = 15;
    healthLabel.fontColor = [SKColor redColor];
    healthLabel.text = [NSString stringWithFormat:@"Hero: x: 000.0 y: 000.0 world.pos.x: 0  pos.y: 00"];
//    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width/2 - margin, self.size.height - (margin + healthLabel.frame.size.height/2));
//    [self addChild:healthLabel];

//    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width/2 - margin, self.size.height - (margin + healthLabel.frame.size.height/2));
//    healthLabel.position = CGPointMake(self.camera.frame.size.width - healthLabel.frame.size.width/2 - margin, self.camera.frame.size.height - (margin + healthLabel.frame.size.height/2));
    healthLabel.position = CGPointMake(0, 0);

    [self.world addChild:healthLabel];
}

- (void)centerWorldOnHero {
    [self centerWorldOnPosition:self.hero.position];
}

- (void)centerWorldOnPosition:(CGPoint)position {
    
    [self.world setPosition:CGPointMake(-(position.x) + CGRectGetMidY(self.frame),
                                        -(position.y) + CGRectGetMidX(self.frame))];
    
   // self.worldMovedForUpdate = YES;
}

#pragma mark Hero
- (void) moveHeroToPoint:(CGPoint)targetPoint {
    
    if ([self.hero actionForKey:@"move"]) {
        [self.hero removeAllActions];
    }
    
    double angle = atan2(targetPoint.y - _hero.position.y, targetPoint.x - _hero.position.x);
    
    [self.hero runAction:[SKAction rotateToAngle:angle duration:.1]];
    
    SKAction *move = [self moveToWithSpeed:self.hero.position to:targetPoint];
    
    SKAction *done = [SKAction runBlock:^ { [self HeroStopWalking]; }];
    
    SKAction *moveSeq = [SKAction sequence:@[move, done]];
    
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.heroWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    
    [self.hero runAction:sequence withKey:@"move"];
}

- (SKAction *) moveToWithSpeed:(CGPoint)p1 to:(CGPoint)p2 {
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    
    float speed = kHeroWalkSpeed;
    NSTimeInterval duration = distance/speed;
    SKAction *move  = [SKAction moveTo:p2 duration:duration];
    return move;
}


-(void) HeroStopWalking {
    [self.hero removeAllActions]; // todo : only remove walking action
}

-(void) HeroFireGun {
    
    if ([self.world childNodeWithName:kHeroBulletNode] != Nil) {
        NSLog(@"bullet alreay fired");
        return;
    }
    
//    [self HeroStopWalking];

    [self.hero runAction:   [SKAction animateWithTextures:self.heroFireFrames timePerFrame:0.1f resize:NO restore:YES] ];
    
    //add bullet
    SKSpriteNode *projectile = [[self projectile] copy];
    projectile.position = self.hero.position;
    projectile.name = kHeroBulletNode;
    [self.world addChild:projectile];

    CGFloat rot = self.hero.zRotation;
    SKAction *fireAction = [SKAction moveByX:cosf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                          y:sinf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                    duration:kHeroProjectileLifetime];
    /*
    [projectile runAction:[SKAction moveByX:cosf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                          y:sinf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                   duration:kHeroProjectileLifetime]
                        withKey:@"bulletMove"];
     */
    
//    [projectile runAction:[SKAction sequence:@[[SKAction waitForDuration:kHeroProjectileFadeOutTime],
//                                               [SKAction fadeOutWithDuration:kHeroProjectileLifetime - kHeroProjectileFadeOutTime],
//                                               [SKAction removeFromParent]]]];
    
//    [projectile runAction:[SKAction sequence:@[[SKAction waitForDuration:kHeroProjectileLifetime],
      [projectile runAction:[SKAction sequence:@[fireAction,
                                               [
                                                SKAction runBlock:^(void) {
                                                    NSString *burstPath = [[NSBundle mainBundle] pathForResource:@"SmokeParticle" ofType:@"sks"];
                                                    SKEmitterNode *burstNode = [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
                                                    burstNode.position = CGPointMake(projectile.position.x, projectile.position.y);
        
                                                    [self.world addChild:burstNode];
                                                    [projectile runAction:[SKAction removeFromParent]];
                                                    [burstNode runAction:[SKAction sequence:@[
                                                                                               [SKAction waitForDuration:kBulletFadeOutTime],
                                                                                               [SKAction removeFromParent]]]];
                                                }]]]];

}


#pragma mark IOS Events
-(void) ShakeGesture {
    [self HeroFireGun];
}

#pragma mark GameLoop Events
- (void)update:(NSTimeInterval)currentTime
{
}

- (void) didEvaluateActions {
}

- (void)didSimulatePhysics {
   [self centerOnNode: _hero];
    [self updateHudHeroPos];
}

- (void) centerOnNode: (SKNode *) node
{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x,
                                       node.parent.position.y - cameraPositionInScene.y);
}


- (void)alltl_didSimulatePhysics {
    CGPoint heroPosition = self.hero.position;
    int kMinHeroToEdgeDistance = 70;
    
    if (heroPosition.y + kMinHeroToEdgeDistance > self.frame.size.height / 2) {
        NSLog(@" center node.  %.1f", self.frame.size.height);
        [self centerOnNode:_hero];
    }

    [self updateHudHeroPos];
}

- (void)old_didSimulatePhysics {
    CGPoint heroPosition = self.hero.position;
    CGPoint worldPos = self.world.position;
    CGFloat yCoordinate = worldPos.y + heroPosition.y;
    int kMinHeroToEdgeDistance = 130;

      if (yCoordinate < kMinHeroToEdgeDistance) {
          NSLog(@"Center world - 1" );
          [self centerOnNode: _hero];
      }
      else if (yCoordinate > (self.frame.size.height - kMinHeroToEdgeDistance)) {
          NSLog(@"Center world - 2" );
          [self centerOnNode: _hero];
      }
    
   CGFloat xCoordinate = worldPos.x + heroPosition.x;
   if (xCoordinate < kMinHeroToEdgeDistance) {
     //   worldPos.x = worldPos.x - xCoordinate + kMinHeroToEdgeDistance;
//        NSLog(@"Too close to right edge");
    }

//    self.world.position = worldPos;
    [self updateHudHeroPos];
}

- (void) updateHudHeroPos {
    SKLabelNode* posNode = (SKLabelNode*)[self childNodeWithName:kDebugOverlayNode];
    posNode.text = [NSString stringWithFormat:@"Hero x: %.0f y: %.0f", self.hero.position.x, self.world.position.y];

}
@end
