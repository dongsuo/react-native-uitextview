#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef RNUITextViewNativeComponent_h
#define RNUITextViewNativeComponent_h

// 自定义菜单项结构
typedef struct {
  NSString *title;
  NSString *actionId;
} RNUITextViewMenuItem;

NS_ASSUME_NONNULL_BEGIN
@interface RNUITextView : RCTViewComponentView <UITextViewDelegate>

// 自定义菜单项属性
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *customMenuItems;

@end

NS_ASSUME_NONNULL_END

#endif /* UitextviewViewNativeComponent_h */
