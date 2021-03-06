//
//  JMHoledView.m
//  JMHoledView
//
//  Created by jerome morissard on 01/02/2015.
//  Copyright (c) 2015 Jerome Morissard. All rights reserved.
//

#import "JMHoledView.h"

#pragma mark - holes objects
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface JMHole : NSObject
@property (assign) JMHoleType holeType;
@end

@implementation JMHole
@end

@interface JMCircleHole : JMHole
@property (assign) CGPoint holeCenterPoint;
@property (assign) CGFloat holeDiameter;
@end

@implementation JMCircleHole
@end

@interface JMRectHole : JMHole
@property (assign) CGRect holeRect;
@end

@implementation JMRectHole
@end

@interface JMRoundedRectHole : JMRectHole
@property (assign) CGFloat holeCornerRadius;
@end

@implementation JMRoundedRectHole
@end

@interface JMCustomRectHole : JMRectHole
@property (strong) UIView *customView;
@end

@implementation JMCustomRectHole
@end

@interface JMHoledView ()
@property (strong, nonatomic) NSMutableArray *holes;  //Array of JMHole
@end

@implementation JMHoledView

#pragma mark - LifeCycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _holes = [NSMutableArray new];
    self.backgroundColor = [UIColor clearColor];
    _dimingColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDetectedForGesture:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)drawRect:(CGRect)rect
{
    [self removeCustomViews];
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == nil) {
        return;
    }
    
    [self.dimingColor setFill];
    UIRectFill(rect);
    
    for (JMHole* hole in self.holes) {
        
        [[UIColor clearColor] setFill];
        
        if (hole.holeType == JMHoleTypeRoundedRect) {
            JMRoundedRectHole *rectHole = (JMRoundedRectHole *)hole;
            CGRect holeRectIntersection = CGRectIntersection( rectHole.holeRect, self.frame);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:holeRectIntersection
                                                                  cornerRadius:rectHole.holeCornerRadius];
            
            CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [[UIColor clearColor] CGColor]);
            CGContextAddPath(UIGraphicsGetCurrentContext(), bezierPath.CGPath);
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
            CGContextFillPath(UIGraphicsGetCurrentContext());
            
        } else if (hole.holeType == JMHoleTypeRect) {
            JMRectHole *rectHole = (JMRectHole *)hole;
            CGRect holeRectIntersection = CGRectIntersection( rectHole.holeRect, self.frame);
            UIRectFill( holeRectIntersection );
            
        } else if (hole.holeType == JMHoleTypeCirle) {
            JMCircleHole *circleHole = (JMCircleHole *)hole;
            CGRect rectInView = CGRectMake(floorf(circleHole.holeCenterPoint.x - circleHole.holeDiameter*0.5f),
                                           floorf(circleHole.holeCenterPoint.y - circleHole.holeDiameter*0.5f),
                                           circleHole.holeDiameter,
                                           circleHole.holeDiameter);
            CGContextSetFillColorWithColor( context, [UIColor clearColor].CGColor );
            CGContextSetBlendMode(context, kCGBlendModeClear);
            CGContextFillEllipseInRect( context, rectInView );
        }
    }
    
    [self addCustomViews];
}

#pragma mark - Add methods

- (NSInteger)addHoleCircleCenteredOnPosition:(CGPoint)centerPoint andDiameter:(CGFloat)diameter
{
    JMCircleHole *circleHole = [JMCircleHole new];
    circleHole.holeCenterPoint = centerPoint;
    circleHole.holeDiameter = diameter;
    circleHole.holeType = JMHoleTypeCirle;
    [self.holes addObject:circleHole];
    [self setNeedsDisplay];
    
    return [self.holes indexOfObject:circleHole];
}

- (NSInteger)addHoleRectOnRect:(CGRect)rect
{
    JMRectHole *rectHole = [JMRectHole new];
    rectHole.holeRect = rect;
    rectHole.holeType = JMHoleTypeRect;
    [self.holes addObject:rectHole];
    [self setNeedsDisplay];
    
    return [self.holes indexOfObject:rectHole];
}

- (NSInteger)addHoleRoundedRectOnRect:(CGRect)rect withCornerRadius:(CGFloat)cornerRadius
{
    JMRoundedRectHole *rectHole = [JMRoundedRectHole new];
    rectHole.holeRect = rect;
    rectHole.holeCornerRadius = cornerRadius;
    rectHole.holeType = JMHoleTypeRoundedRect;
    [self.holes addObject:rectHole];
    [self setNeedsDisplay];
    
    return [self.holes indexOfObject:rectHole];
}

- (NSInteger)addHCustomView:(UIView *)customView onRect:(CGRect)rect
{
    JMCustomRectHole *customHole = [JMCustomRectHole new];
    customHole.holeRect = rect;
    customHole.customView = customView;
    customHole.holeType = JMHoleTypeCustomRect;
    [self.holes addObject:customHole];
    [self setNeedsDisplay];
    
    return [self.holes indexOfObject:customHole];
}

- (void) addHoleCircleCenteredOnPosition:(CGPoint)centerPoint andDiameter:(CGFloat)diameter withText:(NSString *)text onPosition:(JMHolePosition) pos withMargin:(CGFloat) margin
{
    
    [self addHoleCircleCenteredOnPosition:centerPoint andDiameter:diameter];
    [self buildLabel:centerPoint holeWidth:diameter holeHeight:diameter withText:text onPosition:pos withMargin:margin];
    
}

- (void) addHoleRectOnRect:(CGRect)rect withText:(NSString *)text onPosition:(JMHolePosition) pos withMargin:(CGFloat) margin
{
    [self addHoleRectOnRect:rect];
    [self buildLabel:CGPointMake(rect.origin.x+(rect.size.width/2),rect.origin.y+(rect.size.height/2)) holeWidth:rect.size.width holeHeight:rect.size.height withText:text onPosition:pos withMargin:margin];
}

-(void) addHoleRoundedRectOnRect:(CGRect)rect withCornerRadius:(CGFloat)cornerRadius withText:(NSString *)text onPosition:(JMHolePosition) pos withMargin:(CGFloat) margin
{
    [self addHoleRoundedRectOnRect:rect withCornerRadius:cornerRadius];
    [self buildLabel:CGPointMake(rect.origin.x+(rect.size.width/2),rect.origin.y+(rect.size.height/2)) holeWidth:rect.size.width holeHeight:rect.size.height withText:text onPosition:pos withMargin:margin];
}

- (void)removeHoles
{
    [self removeCustomViews];
    [self.holes removeAllObjects];
    [self setNeedsDisplay];
}

-(UILabel*) buildLabel:(CGPoint)point holeWidth:(CGFloat)width holeHeight:(CGFloat)height withText:(NSString*) text onPosition:(JMHolePosition) pos withMargin:(CGFloat) margin{
    
    CGPoint centerPoint = point;
    CGFloat holeWidthHalf = (width/2) + margin;
    CGFloat holeHeightHalf = (height/2) + margin;
    
    CGRect frame;
    CGSize fontSize;
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        // code here for iOS 5.0,6.0 and so on
        fontSize = [text sizeWithFont:[UIFont systemFontOfSize:14.0f]];
    } else {
        // code here for iOS 7.0
        fontSize = [text sizeWithAttributes:
                    @{NSFontAttributeName:
                          [UIFont systemFontOfSize:14.0f]}];
    }
    CGFloat x;
    CGFloat y;
    switch (pos) {
        case JMPositionTop:
            x = (centerPoint.x)-(fontSize.width/2);
            y = (centerPoint.y-holeHeightHalf)-fontSize.height;
            break;
        case JMPositionTopRightCorner:
            x = (centerPoint.x+holeWidthHalf);
            y = (centerPoint.y-holeHeightHalf)-fontSize.height;
            break;
        case JMPositionRight:
            x = (centerPoint.x+holeWidthHalf);
            y = (centerPoint.y)-(fontSize.height/2);
            break;
        case JMPositionBottomRightCorner:
            x = centerPoint.x+holeWidthHalf;
            y = centerPoint.y+holeHeightHalf;
            break;
        case JMPositionBottom:
            x = (centerPoint.x)-(fontSize.width/2);
            y = (centerPoint.y+holeHeightHalf);
            break;
        case JMPositionBottomLeftCorner:
            x = (centerPoint.x-holeWidthHalf)-(fontSize.width);
            y = (centerPoint.y+holeHeightHalf);
            break;
        case JMPositionLeft:
            x = (centerPoint.x-holeWidthHalf)-(fontSize.width);
            y = (centerPoint.y)-(fontSize.height/2);
            break;
        case JMPositionTopLeftCorner:
            x = (centerPoint.x-holeWidthHalf)-(fontSize.width);
            y = (centerPoint.y-holeHeightHalf)-(fontSize.height/2);
            break;
        default:
            x = centerPoint.x;
            y = centerPoint.y;
            break;
    }
    frame = CGRectMake(x,y, fontSize.width, fontSize.height);
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor whiteColor]];
    label.numberOfLines = 2;
    label.text = text;
    label.font = [UIFont systemFontOfSize:14.0f];
    label.textAlignment = NSTextAlignmentCenter;
    
    [self addHCustomView:label onRect:frame];
    
    return label;
}

#pragma mark - Overided setter

- (void)setDimingColor:(UIColor *)dimingColor
{
    _dimingColor = dimingColor;
    [self setNeedsDisplay];
}

#pragma mark - Tap Gesture

- (void)tapGestureDetectedForGesture:(UITapGestureRecognizer *)gesture
{
    if ([self.holeViewDelegate respondsToSelector:@selector(holedView:didSelectHoleAtIndex:)]) {
        CGPoint touchLocation = [gesture locationInView:self];
        [self.holeViewDelegate holedView:self didSelectHoleAtIndex:[self holeViewIndexForAtPoint:touchLocation]];
    }
}

- (NSUInteger)holeViewIndexForAtPoint:(CGPoint)touchLocation
{    
    __block NSUInteger idxToReturn = NSNotFound;
    [self.holes enumerateObjectsUsingBlock:^(JMHole *hole, NSUInteger idx, BOOL *stop) {
        if (hole.holeType == JMHoleTypeRoundedRect ||
            hole.holeType == JMHoleTypeRect ||
            hole.holeType == JMHoleTypeCustomRect) {
            JMRectHole *rectHole = (JMRectHole *)hole;
            if (CGRectContainsPoint(rectHole.holeRect, touchLocation)) {
                idxToReturn = idx;
                *stop = YES;
            }
            
        } else if (hole.holeType == JMHoleTypeCirle) {
            JMCircleHole *circleHole = (JMCircleHole *)hole;
            CGRect rectInView = CGRectMake(floorf(circleHole.holeCenterPoint.x - circleHole.holeDiameter*0.5f),
                                           floorf(circleHole.holeCenterPoint.y - circleHole.holeDiameter*0.5f),
                                           circleHole.holeDiameter,
                                           circleHole.holeDiameter);
            if (CGRectContainsPoint(rectInView, touchLocation)) {
                idxToReturn = idx;
                *stop = YES;
            }
        }
    }];
    
    return idxToReturn;
}

#pragma mark - Custom Views

- (void)removeCustomViews
{
    [self.holes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[JMCustomRectHole class]]) {
            JMCustomRectHole *hole = (JMCustomRectHole *)obj;
            [hole.customView removeFromSuperview];
        }
    }];
}

- (void)addCustomViews
{
    [self.holes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[JMCustomRectHole class]]) {
            JMCustomRectHole *hole = (JMCustomRectHole *)obj;
            [hole.customView setFrame:hole.holeRect];
            [self addSubview:hole.customView];
        }
    }];
}

@end
