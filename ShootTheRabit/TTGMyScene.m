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

@interface TTGMyScene()
@property (nonatomic) SKSpriteNode *hero;
@property (nonatomic) NSMutableArray *heroWalkFrames;
@property (nonatomic) SKSpriteNode *world;
@property (nonatomic) SKNode *camera;
@end

@implementation TTGMyScene

//CGRect screenRect;
CGFloat screenHeight;
CGFloat screenWidth;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
//        screenRect = [[UIScreen mainScreen] bounds];
//        screenWidth = screenRect.size.height; //landscape! to height is width
//        screenHeight = screenRect.size.width;
        screenWidth = size.width;
        screenHeight = size.height;
        NSLog(@"screenWidth: %.0f  screenHeight: %.0f", screenWidth, screenHeight);

        /* Setup your scene here */
        //background
        /*
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"greenGrassBackground"];
        background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:background];
         */
//        _world = [SKSpriteNode spriteNodeWithImageNamed:@"greenGrassBackground-2"];
        
        
        self.anchorPoint = CGPointMake(0.5, 0.5);  // set anchor to Center of scene
        
//        _world = [SKSpriteNode spriteNodeWithImageNamed:@"test-level-1"];
        _world = [SKSpriteNode spriteNodeWithImageNamed:@"grassField4096"];
//        _world.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
//        [_world setAnchorPoint:CGPointZero];
      //  _world.position = CGPointMake(CGRectGetMidX(_world.frame), CGRectGetMidY(_world.frame));
        [self addChild:_world];
        
        _heroWalkFrames = [NSMutableArray new];
        [_heroWalkFrames addObject: [SKTexture textureWithImageNamed:@"slice02_02"]];
        [_heroWalkFrames addObject: [SKTexture textureWithImageNamed:@"slice03_03"]];
        
        //_camera = [SKNode node];
        //[_world addChild:_camera];

        //        NSLog(@"world size: %.0f x %.0f    (%.0f  %.0f)", _world.size.width, _world.size.height, _world.frame.size.height, _world.frame.size.width);
        
        
        [self createHero];
        
        [self setupHud];
        
 //       [self centerWorldOnHero];
    }
    return self;
}

- (void) createHero {
    _hero = [SKSpriteNode spriteNodeWithImageNamed:@"slice02_02"];
//    _hero.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    _hero.position = CGPointMake(250, 150);
//    [_hero  setAnchorPoint:CGPointMake(350, 350) ];
//    [_hero setAnchorPoint:CGPointZero];
    _hero.name = @"hero";
//    [self addChild:_hero];
    [_world addChild:_hero];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
//    CGPoint newLocation = [[touches anyObject] locationInNode:self];
    CGPoint newLocation = [[touches anyObject] locationInNode:self.world];
    
    [self moveHeroToPoint:newLocation];
}

- (void) moveHeroToPoint:(CGPoint)targetPoint {

    if ([self.hero actionForKey:@"move"]) {
        [self.hero removeAllActions];
    }
    
    double angle = atan2(targetPoint.y - _hero.position.y, targetPoint.x - _hero.position.x);
    
//    NSLog(@"move to x: %.1f y: %.1f  rotate: %.1f", targetPoint.x, targetPoint.y, angle );
    
    [self.hero runAction:[SKAction rotateToAngle:angle duration:.1]];
    
    SKAction *move = [self moveToWithSpeed:self.hero.position to:targetPoint];

    SKAction *done = [SKAction runBlock:^ {
        NSLog(@"move done!");
        [self.hero removeAllActions];
    }];
    
    SKAction *moveSeq = [SKAction sequence:@[move, done]];
//    SKAction *moveSeq = [SKAction sequence:@[move]];
    
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:_heroWalkFrames
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

    float speed = 40;
    NSTimeInterval duration = distance/speed;
    SKAction *move  = [SKAction moveTo:p2 duration:duration];
    return move;
}

-(void)setupHud {
    SKLabelNode* scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    int margin = 10;
    //1
    scoreLabel.name = kScoreHudName;
    scoreLabel.fontSize = 15;
    //2
    scoreLabel.fontColor = [SKColor greenColor];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %02u", 0];
    //3
//    scoreLabel.position = CGPointMake(20 + scoreLabel.frame.size.width/2, self.size.height - (20 + scoreLabel.frame.size.height/2));
    scoreLabel.position = CGPointMake(margin + scoreLabel.frame.size.width/2, screenHeight - (margin + scoreLabel.frame.size.height/2));
//    NSLog(@"label.pos.x: %f   pos.y: %f", scoreLabel.position.x, scoreLabel.position.y);
    
    [self.world addChild:scoreLabel];
    
    SKLabelNode* healthLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
   // healthLabel.zPosition = 2;
    //4
    healthLabel.name = kHeroPosName;
    healthLabel.fontSize = 15;
    //5
    healthLabel.fontColor = [SKColor redColor];
    healthLabel.text = [NSString stringWithFormat:@"Hero: x: 000.0 y: 000.0 world.pos.x: 0  pos.y: 00"];
    //6
//    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width/2 - margin, self.size.height - (margin + healthLabel.frame.size.height/2));
//    [self addChild:healthLabel];
//    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width/2 - margin, self.size.height - (margin + healthLabel.frame.size.height/2));
    [self.world addChild:healthLabel];
}

- (void)centerWorldOnHero {
    [self centerWorldOnPosition:self.hero.position];
}

- (void)centerWorldOnPosition:(CGPoint)position {
    
    CGFloat midx = CGRectGetMidX(self.frame);
    CGFloat midy = CGRectGetMidY(self.frame);
    NSLog(@"centerWorlPos.  midX: %.0f  midY: %.0f", midx, midy);
    
//    [self.world setPosition:CGPointMake(-(position.x) + CGRectGetMidX(self.frame),
//                                        -(position.y) + CGRectGetMidY(self.frame))];
    [self.world setPosition:CGPointMake(-(position.x) + CGRectGetMidY(self.frame),
                                        -(position.y) + CGRectGetMidX(self.frame))];
    
   // self.worldMovedForUpdate = YES;
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
       // worldPos.y = worldPos.y - yCoordinate + kMinHeroToEdgeDistance;
       // NSLog(@"Too close to top! hero.pos.y: %.1f hero.pos.x:  %.1f   world.pos.y: %.1f", heroPosition.y, heroPosition.x, worldPos.y);
          [self centerOnNode: _hero];
      }
//      else if (yCoordinate > (screenHeight - kMinHeroToEdgeDistance)) {
      else if (yCoordinate > (self.frame.size.height - kMinHeroToEdgeDistance)) {
          NSLog(@"Center world - 2" );
          //float oldPosY = worldPos.y;
        //worldPos.y = worldPos.y + (self.frame.size.height - yCoordinate) - kMinHeroToEdgeDistance;
//          worldPos.y = worldPos.y + (screenHeight - yCoordinate) - kMinHeroToEdgeDistance ;
//          worldPos.x = 400;
         // NSLog(@"move worldPos.y from %.1f to %.1f   screenHeight: %.1f yCoord: %.1f  minDistance: %.1d", oldPosY, worldPos.y, screenHeight, yCoordinate, kMinHeroToEdgeDistance );
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
    SKLabelNode* posNode = (SKLabelNode*)[self.world childNodeWithName:kHeroPosName];
//    posNode.text = [NSString stringWithFormat:@"Hero: x: %.1f y: %.1f  world.x: %.1f y: %.1f", self.hero.position.x, self.hero.position.y, self.world.position.x, self.world.position.y];
    
    CGPoint heroPosition = self.hero.position;
    CGPoint worldPos = self.world.position;
    CGFloat yCoordinate = worldPos.y + heroPosition.y;

    posNode.text = [NSString stringWithFormat:@"Hero.y: %.0f  world.y: %.0f  yCoord: %.0f  world.x: %.0f", self.hero.position.y, self.world.position.y, yCoordinate, self.world.position.x];

}
@end
