//
//  TTGMyScene.m
//  ShootTheRabit
//
//  Created by Jim on 12/27/13.
//  Copyright (c) 2013 TangoTiger. All rights reserved.
//

#import "TTGMyScene.h"
@import AVFoundation;

#define kScoreHudName @"scoreHud"
#define kHeroPosName @"heroPos"
#define kDebugOverlayNode @"debugOverlayName"
#define kHeroBulletNode @"heroBulletNode"
#define kPlayerPosLabel  @"playerPos"
#define kGameStatLabel @"gameStats"
#define kGameDebugLabel @"debugMode"

#define kHeroWalkSpeed 60  // higher number, faster move
#define kHeroWalkDistance 600.0  // higher number, farther move

// copied from 'Adventure'
#define kHeroProjectileSpeed 220.0
#define kHeroProjectileLifetime 1.1
//#define kHeroProjectileFadeOutTime 0.5
#define kBulletFadeOutTime 4.0
#define kRabbitRunDuration 1.5
#define kRabbitRunSpeed 180.0  // Distance??

static const int kNumberOfHeroWalkingImages = 3;
static const int kNumberOfHeroFiringImages = 2;
static const int kNumberOfRabbitWalkingImages = 4;
static const int kMinDistanceForceRabbitRunAway = 130;
static const int wallSize = 10;

static const uint32_t heroCategory     =  0x1 << 0;
static const uint32_t projectileCategory  =  0x1 << 1;
static const uint32_t rabbitCategory   =  0x1 << 2;
//static const uint32_t wallCategory = 0x1 << 3;


@interface TTGMyScene()
@property (nonatomic) SKSpriteNode *hero;
@property (nonatomic) SKSpriteNode *rabbit; //assume, only 1 for now
@property (nonatomic) SKSpriteNode *world;
@property (nonatomic) SKNode *gameHudNode;
@property (nonatomic) SKNode *rabbitFinder;
@property (nonatomic) SKSpriteNode *projectile;
@property (nonatomic) NSMutableArray *heroWalkFrames;
@property (nonatomic) NSMutableArray *heroFireFrames;
@property (nonatomic) NSMutableArray *rabbitWalkFrames;
@property (nonatomic) AVAudioPlayer * backgroundMusicPlayer;


@property (nonatomic) NSInteger worldMaxX;
@property (nonatomic) NSInteger worldMaxY;
@property (nonatomic) NSInteger worldMinX;
@property (nonatomic) NSInteger worldMinY;

@end

@implementation TTGMyScene

//NSString * const kBackgroudImageName = @"grassField4096";
NSString * const kBackgroudImageName = @"grassFieldAndWall";
NSString * const kHeroStandImage = @"heroStand";
NSString * const kRabbitStandImage = @"rabbit_stand";
NSString * const kRabbitArrowImage = @"arrow3";
NSString * const kActionRabbitMove = @"moveRabbit";
NSString * const kActionRabbitMoveTooClose = @"moveRabbitTooClose";
NSString * const kSoundGunFire = @"handgun_500a.m4a";
NSString * const kSoundAnimalKil = @"animal_hit.m4a";
NSString * const kSoundBackgroundMusic = @"CongoLoop.m4a";
const float kBackgroundVolume = 0.3f;

//CGRect screenRect;
CGFloat screenHeight;
CGFloat screenWidth;
int rabbitKills = 0;
bool isDebugModeOn = false;

#pragma mark Vector Math

// Vector math from http://www.raywenderlich.com/42699/spritekit-tutorial-for-beginners
static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

#pragma mark initialize
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [self initializeGame:size];
    }
    return self;
}

- (void) initializeGame:(CGSize) size {
    if (_world != nil ) {
        NSLog(@"early exit - already initialzed");
    }
    
    screenWidth = size.width;
    screenHeight = size.height;
    //        NSLog(@"screenWidth: %.0f  screenHeight: %.0f", screenWidth, screenHeight);
    
    self.anchorPoint = CGPointMake(0.5, 0.5);  // set anchor to Center of scene
    
    _world = [SKSpriteNode spriteNodeWithImageNamed:kBackgroudImageName];
    _worldMaxX = (_world.size.width /2) - wallSize;
    _worldMaxY = (_world.size.height/2) - wallSize;
    _worldMinX = _worldMaxX * -1;
    _worldMinY = _worldMaxY * -1;
    //        _world.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:_world.frame];
    
    [self addChild:_world];
    
    NSLog(@"world %.01f %.01f", _world.position.x, _world.position.y);
    
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
    
    [self startBackgroundMusic];
}

- (void) createHero {
    SKTexture *heroStand = [SKTexture textureWithImageNamed:kHeroStandImage];
    _hero = [SKSpriteNode spriteNodeWithTexture:heroStand];
    
    _hero.position = CGPointMake(700, 790);
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
    
    NSLog(@"Rabbit created at x,y:  %.0f %.0f   hero.pos: %.0f %.0f", self.rabbit.position.x, self.rabbit.position.y, self.hero.position.x, self.hero.position.y);
    
    [self.world addChild:_rabbit];
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
//            [self moveHeroToPoint:touchLocationInWorld];
            [self moveHeroInDirectionOfPoint:touchLocationInWorld];
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
}

- (void) killAnimal:(SKSpriteNode *) animal {
    SKAction *rabbitDie = [SKAction rotateByAngle:180 duration:.6];
    SKAction *sound = [SKAction playSoundFileNamed:kSoundAnimalKil waitForCompletion:NO];

    SKAction *foo = [SKAction scaleBy:.40 duration:.6];
    SKAction *group = [SKAction group:@[rabbitDie, foo, sound]];
    
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
    labelPosition.position = CGPointMake(70, 0);
    [_gameHudNode addChild:labelPosition];

    SKLabelNode *gameStats = [self createDefaultHudLabel:kGameStatLabel];
    gameStats.text = @"stats...";
    gameStats.position = CGPointMake(screenWidth - 100, 0);
    [_gameHudNode addChild:gameStats];
    
    SKLabelNode *debug = [self createDefaultHudLabel:kGameDebugLabel];
    debug.text = @"debug off";
    debug.position = CGPointMake(0, 0);
    [_gameHudNode addChild:debug];
    
    
    _rabbitFinder = [SKNode new];
    _rabbitFinder.position = CGPointMake(screenWidth/2, 0);

    SKSpriteNode *arrow = [SKSpriteNode spriteNodeWithImageNamed:kRabbitArrowImage];
    arrow.name = @"hudArrow";
    arrow.size = CGSizeMake(20, 20);
    [_rabbitFinder addChild:arrow];
    
    SKLabelNode *rabbitDistance = [self createDefaultHudLabel:@"distance"];
    rabbitDistance.position = CGPointMake((arrow.size.width/2) * -1, (arrow.size.height) * -1);
    rabbitDistance.text = @"xxx";
    [_rabbitFinder addChild:rabbitDistance];
                                   
    [_gameHudNode addChild:_rabbitFinder];
    
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
    
    double angle = atan2(self.rabbit.position.y - self.hero.position.y, self.rabbit.position.x - self.hero.position.x);
    SKSpriteNode *arrow = (SKSpriteNode*) [self.rabbitFinder childNodeWithName:@"hudArrow"];
    [arrow runAction:[SKAction rotateToAngle:angle duration:.1]];
    
    SKLabelNode *distanceNode = (SKLabelNode*) [self.rabbitFinder childNodeWithName:@"distance"];
    CGFloat distance = [self distanceBetweenTwoPoints:self.rabbit.position and:self.hero.position] - self.hero.size.width;
    distanceNode.text = [NSString stringWithFormat:@"%d", abs(distance/ 5)];
}

/*
- (void)centerWorldOnHero {
    [self centerWorldOnPosition:self.hero.position];
}

- (void)centerWorldOnPosition:(CGPoint)position {
    
    [self.world setPosition:CGPointMake(-(position.x) + CGRectGetMidY(self.frame),
                                        -(position.y) + CGRectGetMidX(self.frame))];
    
   // self.worldMovedForUpdate = YES;
}
 */

- (void) startBackgroundMusic {
    /*
    NSError *error;
    NSURL * backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"CongoLoop" withExtension:@"m4a"];

    self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    self.backgroundMusicPlayer.numberOfLoops = -1;
    [self.backgroundMusicPlayer prepareToPlay];
    [self.backgroundMusicPlayer play];
    NSLog(@"music error: %@", error);
     */
    
    NSError *err;
    NSURL *file = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:kSoundBackgroundMusic ofType:nil]];
    self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:&err];
    if (err) {
        NSLog(@"error in audio play %@",[err userInfo]);
        return;
    }
    [self.backgroundMusicPlayer prepareToPlay];
    
    // this will play the music infinitely
    self.backgroundMusicPlayer.numberOfLoops = -1;
    [self.backgroundMusicPlayer setVolume:kBackgroundVolume];
    [self.backgroundMusicPlayer play];
}

#pragma mark Hero
- (void) moveHeroToPoint:(CGPoint)targetPoint {
    
    // OLD WAY, see moveHeroInDirectionOfPoint
    if ([self.hero actionForKey:@"move"]) {
        [self.hero removeAllActions];
    }
    
    targetPoint = [self adjustPointWithinWorldBounds:targetPoint];

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

- (void) moveHeroInDirectionOfPoint:(CGPoint) targetPoint {

    if ([self.hero actionForKey:@"move"]) {
        [self.hero removeAllActions];
    }

    double angle = atan2(targetPoint.y - _hero.position.y, targetPoint.x - _hero.position.x);
    
    [self.hero runAction:[SKAction rotateToAngle:angle duration:.1]];
    
    CGPoint offset = rwSub(self.hero.position, targetPoint);
    offset.x *= -1;   //wtf, need '-1' to get direction correct
    offset.y *= -1;
    
    CGPoint direction = rwNormalize(offset);
    CGPoint moveAmount = rwMult(direction, kHeroWalkDistance);
    CGPoint endPoint= rwAdd(moveAmount, self.hero.position);
    
    endPoint = [self adjustPointWithinWorldBounds:endPoint];
    
    //NSLog(@"touch: %.01f,%.01f  endP: %.01f,%.01f", targetPoint.x, targetPoint.y, endPoint.x, endPoint.y);
    SKAction *move = [self moveToWithSpeed:self.hero.position to:endPoint];

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

- (CGPoint) adjustPointWithinWorldBounds:(CGPoint) targetPoint {
    const int maxX = self.worldMaxX - (self.hero.size.width /2);
    const int maxY = self.worldMaxY - (self.hero.size.height);
    const int minX = (int)self.worldMinY;
    const int minY = (int)self.worldMinY;
    
    if (targetPoint.x < minX ){
        targetPoint.x = minX;
    }
    else if (targetPoint.x > maxX ){
        targetPoint.x = maxX;
    }
    
    if (targetPoint.y < minY) {
        targetPoint.y = minY;
    }
    else if (targetPoint.y > maxY) {
        targetPoint.y = maxY;
    }
    
    return targetPoint;
}

- (CGFloat) distanceBetweenTwoPoints:(CGPoint) p1 and:(CGPoint)p2 {
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (SKAction *) moveToWithSpeed:(CGPoint)p1 to:(CGPoint)p2 {
    
    CGFloat distance = [self distanceBetweenTwoPoints:p1 and:p2];
    
//    float speed = kHeroWalkSpeed;
    NSTimeInterval duration = distance/kHeroWalkSpeed;
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
    
    
    [self.rabbit runAction:sequence withKey:kActionRabbitMove];
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
    
    [self.rabbit runAction:sequence withKey:kActionRabbitMove];
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
    /*
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
     */
    
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
    
    pointEnd = [self adjustPointWithinWorldBounds:pointEnd]; // should cp1 and cp2 also, but too lazy now
    
    CGPathMoveToPoint(cgpath, NULL, pointStart.x, pointStart.y);
 
//    NSLog(@"start: %.0fx%.0f  cp1: %.0fx%.0f cp2: %.0fx%.0f  END: %.0fx%.0f ", pointStart.x,pointStart.y, pointCP1.x, pointCP1.y, pointCP2.x, pointCP2.y, pointEnd.x, pointEnd.y);
    
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
    
//    [self RabbitStopWalking]; //kill current movement
    [self.rabbit runAction:sequence withKey:kActionRabbitMove];
}

- (bool) isRabbitAlreadyRunning {
    if ([self.rabbit actionForKey:kActionRabbitMoveTooClose] ||
        [self.rabbit actionForKey:kActionRabbitMove] )  {
        return YES;
    }
    
    return NO;
}

- (void ) runRabbitRunTooClose {
    if ([self isRabbitAlreadyRunning]) {
        return;
    }
    
    NSLog(@"runRabbitRunTooClose ** ");
    CGMutablePathRef cgpath = CGPathCreateMutable();
    
    int xMove = [self getRandomNumberBetween:150 to:350];
    int yMove = [self getRandomNumberBetween:150 to:350];
    int x1 = 80;
    int x2 = 150;
    int y1 = (yMove/3);
    int y2 = 100;
    
    const int minDistanceToWall =50;
    
    if (self.rabbit.position.x - minDistanceToWall < self.worldMinX ) {
        //too close to left wall; keep xMove positive - move away from wall
    }
    else if (yMove % 2 == 0 || self.rabbit.position.y + minDistanceToWall > self.worldMaxY) {
        yMove *= -1;
        y1 *= -1;
        y2 *= -1;
    }

    if (self.rabbit.position.y - minDistanceToWall < self.worldMinY ) {
        //too close to bottom wall; keep yMove positive - move away from wall
    }
    else if (xMove % 2 == 0 || self.rabbit.position.x + minDistanceToWall > self.worldMaxX) {
        xMove *= -1;
        x1 *= -1;
        x2 *= -1;
    }


//    if (self.rabbit.position.x > self.)
    
    CGPoint pointStart = CGPointMake(self.rabbit.position.x, self.rabbit.position.y);
    CGPoint pointEnd = CGPointMake(pointStart.x + xMove, pointStart.y + yMove);
    
    CGPoint pointCP1 = CGPointMake(pointStart.x + xMove + x1, pointStart.y + y1);
    CGPoint pointCP2 = CGPointMake(pointStart.x + xMove + x2, pointCP1.y + y2);
    
    pointEnd = [self adjustPointWithinWorldBounds:pointEnd]; // should cp1 and cp2 also, but too lazy now
    
    CGPathMoveToPoint(cgpath, NULL, pointStart.x, pointStart.y);
    
    //    NSLog(@"start: %.0fx%.0f  cp1: %.0fx%.0f cp2: %.0fx%.0f  END: %.0fx%.0f ", pointStart.x,pointStart.y, pointCP1.x, pointCP1.y, pointCP2.x, pointCP2.y, pointEnd.x, pointEnd.y);
    
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
    
    //    [self RabbitStopWalking]; //kill current movement
    [self.rabbit runAction:sequence withKey:kActionRabbitMoveTooClose];
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
    
    
    [self.rabbit runAction:sequence withKey:kActionRabbitMove];

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
    
    [self HeroStopWalking];

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
    
    SKAction *sound = [SKAction playSoundFileNamed:@"handgun_500a.m4a" waitForCompletion:NO];


    [projectile runAction:[SKAction sequence:@[sound, fireAction,
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
    [self HeroStopWalking];
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
    
    CGFloat distance = [self distanceBetweenTwoPoints:self.hero.position and:self.rabbit.position];
    if (distance < kMinDistanceForceRabbitRunAway) {
        [self runRabbitRunTooClose];
    }
}

- (void) centerOnNode: (SKNode *) node
{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    
   // NSLog(@"centerOnNode  %.0f  %.0f  %d", node.parent.position.x, self.hero.position.x, (int)(self.world.size.width /2));
    
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x,
                                       node.parent.position.y - cameraPositionInScene.y);
}

@end
