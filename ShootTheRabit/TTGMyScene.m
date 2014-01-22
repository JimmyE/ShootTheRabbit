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
#define kPlayerPosLabel  @"playerPos"
#define kGameStatLabel @"gameStats"
#define kGameDebugLabel @"debugMode"

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
@property (nonatomic) SKNode *gameHudNode;
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
int rabbitKills = 0;
bool isDebugModeOn = true;

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
    if (self.rabbit.parent != nil ) {
        NSLog(@"createRabbit called, but rabbit already exists on game");
        return;
    }
    
    SKTexture *rabbitTexture = [SKTexture textureWithImageNamed:kRabbitStandImage];
    _rabbit = [SKSpriteNode spriteNodeWithTexture:rabbitTexture];
    
    /*
    int startX = self.hero.position.x +[self getRandomNumberBetween:-100 to:100];
    int startY = self.hero.position.y +[self getRandomNumberBetween:-100 to:100];
    
    if (self.world.size.width / 2 > startX) {
        startX = [self getRandomNumberBetween:20 to:self.world.size.width / 2 - 20];
    }

    if (self.world.size.height /2 > startY) {
        startY = [self getRandomNumberBetween:20 to:self.world.size.height /2 - 20];
    }
     */
    
    int startX = self.hero.position.x + 80;
    int startY = self.hero.position.y - 80;
    // todo: check bounds
    
//    _rabbit.position = CGPointMake(self.hero.position.x, self.hero.position.y);
    _rabbit.position = CGPointMake(startX, startY);
    _rabbit.name = @"rabbit";
    
    _rabbit.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_rabbit.size];
    _rabbit.physicsBody.dynamic = YES;
    _rabbit.physicsBody.categoryBitMask = rabbitCategory;
    _rabbit.physicsBody.contactTestBitMask = projectileCategory;
    _rabbit.physicsBody.collisionBitMask = heroCategory;
    
    [self.world addChild:_rabbit];
    
    NSLog(@"Rabbit created at x,y:  %.0f %.0f   hero.pos: %.0f %.0f", self.rabbit.position.x, self.rabbit.position.y, self.hero.position.x, self.hero.position.y);
    
    [self runRabbitRunAlt2];
    
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
            CGPoint touchLocation = [[touches anyObject] locationInNode:self];
            SKNode *node = [self nodeAtPoint:touchLocation];
            if ([node.name isEqualToString:kGameDebugLabel]) {
                isDebugModeOn = !isDebugModeOn;
            }
            
            CGPoint touchLocationInWorld = [[touches anyObject] locationInNode:self.world];
            [self moveHeroToPoint:touchLocationInWorld];
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

- (void) killAnimal:(SKSpriteNode *) animal {
    SKAction *rabbitDie = [SKAction rotateByAngle:180 duration:.6];
    SKAction *foo = [SKAction scaleBy:.40 duration:.6];
    SKAction *group = [SKAction group:@[rabbitDie, foo]];
    
    SKAction *remove = [SKAction removeFromParent];
    
    [animal removeAllActions];
    [animal runAction: [SKAction sequence:@[group, remove]]];
    rabbitKills++;
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithRabbit:(SKSpriteNode *)monster {

    NSLog(@"Rabbit was hit");
    [self killAnimal:monster];
    [self.world runAction:[SKAction waitForDuration:1.5] completion:^(void) {
        [self createRabbit];
    }];
    
}


- (SKLabelNode*) createDefaultHudLabel:(NSString *)labelName  {
    
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
    label.name = labelName;
    label.fontColor = [SKColor redColor];
    label.fontSize = 12;
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    label.position = CGPointMake(0, 0);
    
    return label;
}

-(void) setupHud {
    CGFloat hudX = ((screenWidth /2) * -1) + 20;
    CGFloat hudY = (self.frame.size.height / 2) - 20;
    
    _gameHudNode = [[SKNode alloc] init];
    _gameHudNode.name = kDebugOverlayNode;
    _gameHudNode.position = CGPointMake(hudX, hudY);

    SKLabelNode *labelPosition = [self createDefaultHudLabel:kPlayerPosLabel];
    labelPosition.text = @"starting up...";
    labelPosition.position = CGPointMake(0, 0);
    [_gameHudNode addChild:labelPosition];

    SKLabelNode *gameStats = [self createDefaultHudLabel:kGameStatLabel];
    gameStats.text = @"stats...";
    gameStats.position = CGPointMake(screenWidth - 100, 0);
    [_gameHudNode addChild:gameStats];
    
    SKLabelNode *debug = [self createDefaultHudLabel:kGameDebugLabel];
    debug.text = @"debug off";
    debug.position = CGPointMake(screenWidth/2, 0);
    [_gameHudNode addChild:debug];
    
//    [self.world addChild:hud]; //doens't move when player moves
    [self addChild:_gameHudNode];
}

- (void) updateHudHeroPos {
    NSString *rabbitInfo = [NSString stringWithFormat:@"%.0f %.0f", self.rabbit.position.x, self.rabbit.position.y];
    
    if (self.rabbit.parent == nil) {
        rabbitInfo = @" --";
    }
    
//    SKNode* hudNode = (SKNode*)[self childNodeWithName:kDebugOverlayNode];
    SKLabelNode *posNode = (SKLabelNode*) [self.gameHudNode childNodeWithName:kPlayerPosLabel];
    SKLabelNode *stats = (SKLabelNode*) [self.gameHudNode childNodeWithName:kGameStatLabel];
    SKLabelNode *debug = (SKLabelNode*) [self.gameHudNode childNodeWithName:kGameDebugLabel];
    
    stats.text = [NSString stringWithFormat:@"Kills: %d", rabbitKills];
    
    if (isDebugModeOn) {
        debug.text = @"debug ON";
        posNode.text = [NSString stringWithFormat:@"Hero: %.0f %.0f  Rabbit: %@", self.hero.position.x, self.hero.position.y, rabbitInfo ];
    }
    else {
        debug.text = @"debug off";
        posNode.text = @"";
    }
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
    
    SKAction *rotate = [SKAction rotateByAngle:angleDelta duration:.2];
    
    CGFloat rot = self.rabbit.zRotation;
    SKAction *move = [SKAction moveByX:cosf(rot)*kRabbitRunSpeed
                                           y:sinf(rot)*kRabbitRunSpeed
                                    duration:kRabbitRunDuration];

    SKAction *done = [SKAction runBlock:^ { [self RabbitStopWalking]; }];
    SKAction *moveSeq = [SKAction sequence:@[ move, rotate, done]];
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.rabbitWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    
    [self.rabbit runAction:sequence withKey:@"moveRabbit"];
}

- (void) runRabbitRunAlt1 {
    CGMutablePathRef cgpath = CGPathCreateMutable();
    
//    int width1 = self.rabbit.size.width;
//    int height1 = self.rabbit.size.height;
    
//    int width2 = screenWidth;
//    int height2 = screenHeight;
    
    int yStart = self.rabbit.position.y;
    int yEnd = self.rabbit.position.y + [self getRandomNumberBetween:-200 to:200];
    // TODO * Check Bounds of World
    
    float xStart = self.rabbit.position.x;
    float xEnd = self.rabbit.position.x + [self getRandomNumberBetween:-150 to:350];
    //ControlPoint1
    float cp1X = [self getRandomNumberBetween:xStart - 50 to:xStart + 250 ];
    float cp1Y = [self getRandomNumberBetween:yStart - 50 to:yStart + 250 ];
    //ControlPoint2
    float cp2X = [self getRandomNumberBetween:cp1X - 50 to:cp1X  + 150 ];
    float cp2Y = [self getRandomNumberBetween:cp1Y - 30 to:cp1Y + 130];
    CGPoint s = CGPointMake(xStart, yStart);
    CGPoint e = CGPointMake(xEnd, yEnd);
    CGPoint cp1 = CGPointMake(cp1X, cp1Y);
    CGPoint cp2 = CGPointMake(cp2X, cp2Y);
    CGPathMoveToPoint(cgpath,NULL, s.x, s.y);
    
    CGPathAddCurveToPoint(cgpath, NULL, cp1.x, cp1.y, cp2.x, cp2.y, e.x, e.y);
    
    SKAction *rabbitPath = [SKAction followPath:cgpath asOffset:NO orientToPath:YES duration:3];
    
//    [self.rabbit runAction:planePath];
    SKAction *done = [SKAction runBlock:^ { [self RabbitStopWalking]; }];
    SKAction *moveSeq = [SKAction sequence:@[ rabbitPath, done]];
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.rabbitWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    [self.rabbit runAction:sequence withKey:@"moveRabbit"];
}

- (int) calcDistanceBetween:(int)point1 and:(int)point2 {
    if (point1 > point2) {
        return point1 - point2;
    }
    
    return point2 - point1;
}

- (void) runRabbitRunAlt2 {
    NSLog(@"runRabbitRunAlt2");
    CGMutablePathRef cgpath = CGPathCreateMutable();
    
    // TODO * Check Bounds of World

    int xStart = self.rabbit.position.x;
    int yStart = self.rabbit.position.y;

    int xMove = [self getRandomNumberBetween:100 to:400];
    int yMove = [self getRandomNumberBetween:100 to:400];
    
    if (abs(self.hero.position.y - self.rabbit.position.y) <= 70) {
        //too close
        if (self.hero.position.y > self.rabbit.position.y) {
            NSLog(@"too close on y");
            yMove *= -1;
        }
    }
    else if (abs(self.hero.position.x - self.rabbit.position.x) <= 70) {
        //to close
        if (self.hero.position.x > self.rabbit.position.x) {
            NSLog(@"too close on x");
            xMove *= -1;
        }
    }
    else
    {
        if (xMove %2 == 0 ){
            xMove *= -1;
        }
        if (yMove %2 != 0) {
            yMove *= -1;
        }
    }
    
//    int xEnd = self.rabbit.position.x + [self getRandomNumberBetween:-250 to:250];
//    int yEnd = self.rabbit.position.y + [self getRandomNumberBetween:-200 to:200];
    int xEnd = self.rabbit.position.x + xMove;
    int yEnd = self.rabbit.position.y + yMove;
    
    if (xEnd < 0 ) {
  //      xEnd = 20;
    }
    else if (xEnd >= screenWidth ) {
        NSLog(@"adjust xEnd to less than screenWidth: %.0f  xEnd: %d", screenWidth, xEnd);
        xEnd = screenWidth - 20;
    }
    
    if (yEnd < 0 ){
//        yEnd = 20;
    }
    else if (yEnd >= screenHeight) {
        yEnd = screenHeight - 20;
        NSLog(@"adjust yEnd to less than screenHeight");
    }
    
    int xDistance = [self calcDistanceBetween:xStart and:xEnd];
    int yDistance = [self calcDistanceBetween:yStart and:yEnd];
    
    
    //ControlPoint1
    int cp1X = xStart + [self getRandomNumberBetween:20 to:(xDistance/2) ];
    int cp1Y = yStart + [self getRandomNumberBetween:20 to:(yDistance/2) ];
    
    //ControlPoint2
    int cp2X = [self getRandomNumberBetween:cp1X to:xEnd];
    int cp2Y = [self getRandomNumberBetween:cp1Y to:yEnd];
    
    CGPoint pointStart = CGPointMake(xStart, yStart);
    CGPoint pointEnd = CGPointMake(xEnd, yEnd);
    CGPoint pointCP1 = CGPointMake(cp1X, cp1Y);
    CGPoint pointCP2 = CGPointMake(cp2X, cp2Y);
    CGPathMoveToPoint(cgpath, NULL, pointStart.x, pointStart.y);
    
    NSLog(@"start: %.0fx%.0f  cp1: %.0fx%.0f cp2: %.0fx%.0f  END: %.0fx%.0f ", pointStart.x,pointStart.y, pointCP1.x, pointCP1.y, pointCP2.x, pointCP2.y, pointEnd.x, pointEnd.y);
    
    CGPathAddCurveToPoint(cgpath, NULL, pointCP1.x, pointCP1.y, pointCP2.x, pointCP2.y, pointEnd.x, pointEnd.y);
    
    SKAction *rabbitPath = [SKAction followPath:cgpath asOffset:NO orientToPath:YES duration:3];
    
    //    [self.rabbit runAction:planePath];
    SKAction *done = [SKAction runBlock:^ { [self RabbitStopWalking]; }];
    SKAction *moveSeq = [SKAction sequence:@[ rabbitPath, done]];
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.rabbitWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    if (isDebugModeOn ) {
//
        SKNode *foo = [self.world childNodeWithName:@"pathPoints"];
        while (foo != nil ){
            [foo removeFromParent];
            foo = [self.world childNodeWithName:@"pathPoints"];
        }
        
        SKShapeNode *pNode = [SKShapeNode new];
//        roke and fill = 2 nodes
        CGMutablePathRef myPath = CGPathCreateMutable();
        CGPathAddArc(myPath, NULL, 0, 0, 4, 0, M_PI*2, YES);
        pNode.path = myPath;
        pNode.fillColor = [SKColor blueColor];
        pNode.position = pointCP1;
        pNode.name = @"pathPoints";
        [self.world addChild:pNode];
        
        SKShapeNode *p2 = [pNode copy];
        p2.position = pointCP2;
        [self.world addChild:p2];

        SKShapeNode *pS = [pNode copy];
        pS.position = pointStart;
        pS.fillColor = [SKColor redColor];
        [self.world addChild:pS];
    }
    
    [self.rabbit runAction:sequence withKey:@"moveRabbit"];
}

- (void) RabbitCharge {
    NSLog(@"Charge the hero");
    
    // charge the hunter
    // todo: refactor, pretty much a copy of moveHeroToPoint
    CGPoint targetPoint = self.hero.position;
    
    double angle = atan2(targetPoint.y - self.rabbit.position.y, targetPoint.x - self.rabbit.position.x);
    
    [self.rabbit runAction:[SKAction rotateToAngle:angle duration:.1]];

    targetPoint.x += 30;
    targetPoint.y += 20;
    
    SKAction *move = [self moveToWithSpeed:self.rabbit.position to:targetPoint];
    
    SKAction *done = [SKAction runBlock:^ { [self RabbitStopWalking]; }];
    
    SKAction *moveSeq = [SKAction sequence:@[move, done]];
    
    SKAction *sequence = [SKAction group:@[moveSeq,
                                           [SKAction repeatActionForever:
                                            [SKAction animateWithTextures:self.rabbitWalkFrames
                                                             timePerFrame:0.1f
                                                                   resize:NO
                                                                  restore:YES]]
                                           ]];
    
    
    [self.rabbit runAction:sequence withKey:@"moveRabbit"];

}

-(int)getRandomNumberBetween:(int)from to:(int)to {
    if (from > to) {
        int temp = from;
        from = to;
        to = temp;
    }
    return (int)from + arc4random() % (to-from+1);
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
    
    

    SKAction *pause = [SKAction waitForDuration:0.1];
    [self.rabbit runAction:pause];  // very small pause before rabbit takes off
//    [self runRabbitRun];
//    [self runRabbitRunAlt1];
    [self runRabbitRunAlt2];
}


#pragma mark IOS Events
-(void) ShakeGesture {
   [self RabbitCharge];
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

@end
