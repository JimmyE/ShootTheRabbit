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
#define kRabbitRunDuration 1.5
#define kRabbitRunSpeed 180.0  // Distance??

const int kNumberOfHeroWalkingImages = 3;
const int kNumberOfHeroFiringImages = 2;
const int kNumberOfRabbitWalkingImages = 4;

static const uint32_t heroCategory     =  0x1 << 0;
static const uint32_t projectileCategory  =  0x1 << 1;
static const uint32_t rabbitCategory   =  0x1 << 2;


@interface TTGMyScene()
@property (nonatomic) SKSpriteNode *hero;
@property (nonatomic) SKSpriteNode *rabbit; //assume, only 1 for now
@property (nonatomic) SKSpriteNode *world;
@property (nonatomic) SKSpriteNode *projectile;
@property (nonatomic) NSMutableArray *heroWalkFrames;
@property (nonatomic) NSMutableArray *heroFireFrames;
@property (nonatomic) NSMutableArray *rabbitWalkFrames;
@end

@implementation TTGMyScene

NSString * const kBackgroudImageName = @"grassField4096";
NSString * const kHeroStandImage = @"heroStand";
NSString * const kRabbitStandImage = @"rabbit_stand";

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
        _rabbitWalkFrames = [NSMutableArray new];
        
        SKTextureAtlas *heroAtlas = [SKTextureAtlas atlasNamed:@"hero"];
        SKTextureAtlas *rabbitAtlas = [SKTextureAtlas atlasNamed:@"rabbit"];
        
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

        for (int i = 0; i < kNumberOfRabbitWalkingImages; i++) {
            NSString *textureName = [NSString stringWithFormat:@"rabbit_walk_%01d", i + 1];  //use 'i + 1', since images start with '1'
            SKTexture *temp = [rabbitAtlas textureNamed:textureName];
            [_rabbitWalkFrames addObject:temp];
        }

        
        [SKTexture preloadTextures:_heroFireFrames withCompletionHandler:^(void ) {}];
        [SKTexture preloadTextures:_heroWalkFrames withCompletionHandler:^(void){
            [self createHero];  //preload image, else hero "flashes white" when first starting to move

            [SKTexture preloadTextures:_rabbitWalkFrames withCompletionHandler:^(void) {
                [self createRabbit];
            }];
        }];

        
        _projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
        _projectile.xScale = 0.5;
        _projectile.yScale = 0.5;
        
        self.physicsWorld.gravity = CGVectorMake(0, 0); // no gravity!
        self.physicsWorld.contactDelegate = self;
        
        [self setupHud];
    }
    return self;
}

- (void) createHero {
    SKTexture *heroStand = [SKTexture textureWithImageNamed:kHeroStandImage];
    _hero = [SKSpriteNode spriteNodeWithTexture:heroStand];
    
    _hero.position = CGPointMake(250, 150);
    _hero.name = @"hero";
    _hero.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_hero.size];
    _hero.physicsBody.dynamic = YES;
    _hero.physicsBody.categoryBitMask = heroCategory;
    _hero.physicsBody.contactTestBitMask = 0;
    _hero.physicsBody.collisionBitMask = rabbitCategory;
    
    [self.world addChild:_hero];

    NSLog(@"Hero created at x,y:  %.0f %.0f", self.hero.position.x, self.hero.position.y);
}

- (void) createRabbit {
    SKTexture *rabbitTexture = [SKTexture textureWithImageNamed:kRabbitStandImage];
    _rabbit = [SKSpriteNode spriteNodeWithTexture:rabbitTexture];
    
//    _rabbit.position = CGPointMake(250, 150);
    _rabbit.position = CGPointMake(self.hero.position.x - 140, self.hero.position.y);
    _rabbit.name = @"rabbit";
    
    _rabbit.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_rabbit.size];
    _rabbit.physicsBody.dynamic = YES;
    _rabbit.physicsBody.categoryBitMask = rabbitCategory;
    _rabbit.physicsBody.contactTestBitMask = projectileCategory;
    _rabbit.physicsBody.collisionBitMask = heroCategory;
    
    [self.world addChild:_rabbit];
    
    NSLog(@"Rabbit created at x,y:  %.0f %.0f   hero.pos: %.0f %.0f", self.rabbit.position.x, self.rabbit.position.y, self.hero.position.x, self.hero.position.y);
    
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

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
        (secondBody.categoryBitMask & rabbitCategory) != 0)
    {
        [self projectile:(SKSpriteNode *) firstBody.node didCollideWithRabbit:(SKSpriteNode *) secondBody.node];
    }
    
 /*   int bb1 = firstBody.categoryBitMask & rabbitCategory;
    int bb2 = firstBody.categoryBitMask & projectileCategory;
    int bb3 = firstBody.categoryBitMask & heroCategory;
    
    int abb1 = secondBody.categoryBitMask & rabbitCategory;
    int abb2 = secondBody.categoryBitMask & projectileCategory;
    int abb3 = secondBody.categoryBitMask & heroCategory;
    
    NSLog(@"%d %d %d %d %d %d", bb1, bb2, bb3, abb1, abb2, abb3);
   */
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithRabbit:(SKSpriteNode *)monster {

    NSLog(@"Rabbit was hit");
    SKAction *rabbitDie = [SKAction rotateByAngle:180 duration:.6];
    SKAction *foo = [SKAction scaleBy:.40 duration:.6];
    SKAction *group = [SKAction group:@[rabbitDie, foo]];
                      
    SKAction *remove = [SKAction removeFromParent];
                      
    [self.rabbit runAction: [SKAction sequence:@[group, remove]]];
    [self.hero runAction:[SKAction waitForDuration:1.5]];
    [self createRabbit];
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

- (void) RabbitStopWalking {
    [self.rabbit removeAllActions]; // todo: only remove walking action
}

- (NSInteger) randomNumberBetweenMin:(NSInteger)min andMax:(NSInteger)max
{
    return min + arc4random() % (max - min);
}

- (void) runRabbitRun {
    double angleDelta = [self randomNumberBetweenMin:-160 andMax:180];
    NSLog(@"Run Rabbit!  angleDelta %.2f", angleDelta);
    
//    CGFloat angle = self.rabbit.zRotation + angleDelta;
    
//    CGFloat before = self.rabbit.zRotation;
    
//    SKAction *rotate = [SKAction rotateToAngle:angle duration:.1];
    SKAction *rotate2 = [SKAction rotateByAngle:angleDelta duration:.2];
//    [self.rabbit runAction:rotate2];
//    [self.rabbit runAction:[SKAction waitForDuration:.3]];
    
//    NSLog(@"rabbit zRotation. Before: %.2f  after: %.2f", before, self.rabbit.zRotation);
    
    CGFloat rot = self.rabbit.zRotation;
//    SKAction *move = [SKAction moveByX:cosf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
//                                           y:sinf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
//                                    duration:kHeroProjectileLifetime];
    SKAction *move = [SKAction moveByX:cosf(rot)*kRabbitRunSpeed
                                           y:sinf(rot)*kRabbitRunSpeed
                                    duration:kRabbitRunDuration];

    
    SKAction *pause = [SKAction waitForDuration:0.1];
    [self.rabbit runAction:pause];
    
//    [self.rabbit runAction:[SKAction sequence:@[ pause, move]]];
    SKAction *done = [SKAction runBlock:^ { [self RabbitStopWalking]; }];
    SKAction *moveSeq = [SKAction sequence:@[ move, rotate2, done]];
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.rabbitWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    
    [self.rabbit runAction:sequence withKey:@"moveRabbit"];

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
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width/2];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = rabbitCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    [self.world addChild:projectile];

    CGFloat rot = self.hero.zRotation;
    SKAction *fireAction = [SKAction moveByX:cosf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                          y:sinf(rot)*kHeroProjectileSpeed*kHeroProjectileLifetime
                                    duration:kHeroProjectileLifetime];

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
    
    
    [self runRabbitRun];

}


#pragma mark IOS Events
//-(void) ShakeGesture {
 //   [self HeroFireGun];
//}

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
    posNode.text = [NSString stringWithFormat:@"Hero: %.0f %.0f  Rabbit: %.0f %.0f", self.hero.position.x, self.hero.position.y, self.rabbit.position.x, self.rabbit.position.y];

}
@end
