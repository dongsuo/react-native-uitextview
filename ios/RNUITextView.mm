#import "RNUITextView.h"
#import "RNUITextViewShadowNode.h"
#import "RNUITextViewComponentDescriptor.h"
#import "RNUITextViewChild.h"
#import <React/RCTConversions.h>

#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>
#import <objc/runtime.h>
#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>
#import <objc/runtime.h>
#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface RNUITextView () <RCTRNUITextViewViewProtocol, UIGestureRecognizerDelegate, UITextViewDelegate>

// 用于跟踪自定义菜单项
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *menuItemsMap;

@end

@implementation RNUITextView{
  UIView * _view;
  UITextView * _textView;
  RNUITextViewShadowNode::ConcreteState::Shared _state;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNUITextViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNUITextViewProps>();
    _props = defaultProps;

    _view = [[UIView alloc] init];
    self.contentView = _view;
    self.clipsToBounds = true;
    
    // 初始化菜单项映射
    self.menuItemsMap = [NSMutableDictionary new];

    _textView = [[UITextView alloc] init];
    _textView.scrollEnabled = false;
    _textView.editable = false;
    _textView.selectable = YES; // 确保可选择
    _textView.delegate = self; // 设置 delegate 以便自定义菜单
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.userInteractionEnabled = YES; // 确保可交互
    [self addSubview:_textView];

    const auto longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleLongPressIfNecessary:)];
    longPressGestureRecognizer.delegate = self;

    const auto pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handlePressIfNecessary:)];
    pressGestureRecognizer.delegate = self;
    [pressGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];

    [_textView addGestureRecognizer:pressGestureRecognizer];
    [_textView addGestureRecognizer:longPressGestureRecognizer];
    
    // 预注册一些常用的 selector
    SEL translate = NSSelectorFromString(@"customMenuItemAction_translate:");
    SEL share = NSSelectorFromString(@"customMenuItemAction_share:");
    SEL search = NSSelectorFromString(@"customMenuItemAction_search:");

    if (![self respondsToSelector:translate]) {
      class_addMethod([self class], translate, (IMP)customMenuItemIMP, "v@:@");
    }
    if (![self respondsToSelector:share]) {
      class_addMethod([self class], share, (IMP)customMenuItemIMP, "v@:@");
    }
    if (![self respondsToSelector:search]) {
      class_addMethod([self class], search, (IMP)customMenuItemIMP, "v@:@");
    }
  }

  return self;
}

// See RCTParagraphComponentView
- (void)prepareForRecycle
{
  [super prepareForRecycle];
  _state.reset();

  // Reset the frame to zero so that when it properly lays out on the next use
  _textView.frame = CGRectZero;
  _textView.attributedText = nil;
  
  // 清空自定义菜单项
  [self.menuItemsMap removeAllObjects];
  self.customMenuItems = nil;
}

- (void)drawRect:(CGRect)rect
{
  if (!_state) {
    return;
  }

  const auto &props = *std::static_pointer_cast<RNUITextViewProps const>(_props);

  const auto attrString = _state->getData().attributedString;
  const auto convertedAttrString = RCTNSAttributedStringFromAttributedString(attrString);

  _textView.attributedText = convertedAttrString;
  _textView.frame = _view.frame;

  const auto lines = new std::vector<std::string>();
  [_textView.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, convertedAttrString.string.length) usingBlock:^(CGRect rect,
                                                                                              CGRect usedRect,
                                                                                              NSTextContainer * _Nonnull textContainer,
                                                                                              NSRange glyphRange,
                                                                                              BOOL * _Nonnull stop) {
    const auto charRange = [self->_textView.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
    const auto line = [self->_textView.text substringWithRange:charRange];

    if (props.numberOfLines && props.numberOfLines > 0 && lines->size() < props.numberOfLines) {
      lines->push_back(line.UTF8String);
    }
  }];

  if (_eventEmitter != nullptr) {
    std::dynamic_pointer_cast<const facebook::react::RNUITextViewEventEmitter>(_eventEmitter)
    ->onTextLayout(facebook::react::RNUITextViewEventEmitter::OnTextLayout{static_cast<int>(self.tag), *lines});
  };
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNUITextViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNUITextViewProps const>(props);

  if (oldViewProps.numberOfLines != newViewProps.numberOfLines) {
    _textView.textContainer.maximumNumberOfLines = newViewProps.numberOfLines;
  }

  if (oldViewProps.selectable != newViewProps.selectable) {
    _textView.selectable = newViewProps.selectable;
  }

  if (oldViewProps.allowFontScaling != newViewProps.allowFontScaling) {
    if (@available(iOS 11.0, *)) {
      _textView.adjustsFontForContentSizeCategory = newViewProps.allowFontScaling;
    }
  }

  if (oldViewProps.ellipsizeMode != newViewProps.ellipsizeMode) {
    if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Head) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingHead;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Middle) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingMiddle;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Tail) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingTail;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Clip) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByClipping;
    }
  }
  

  // I'm not sure if this is really the right way to handle this style. This means that the entire _view_ the text
  // is in will have this background color applied. To apply it just to a particular part of a string, you'd need
  // to do <Text><Text style={{backgroundColor: 'blue'}}>Hello</Text></Text>.
  // This is how the base <Text> component works though, so we'll go with it for now. Can change later if we want.
  if (oldViewProps.backgroundColor != newViewProps.backgroundColor) {
    _textView.backgroundColor = RCTUIColorFromSharedColor(newViewProps.backgroundColor);
  }
  if (newViewProps.customMenuItems.size() > 0) {
  NSMutableArray *items = [NSMutableArray array];
  for (const auto &item : newViewProps.customMenuItems) {
    [items addObject:@{
      @"title": [NSString stringWithUTF8String:item.title.c_str()],
      @"actionId": [NSString stringWithUTF8String:item.actionId.c_str()]
    }];
  }
  self.customMenuItems = items;
}
  // 自定义菜单项属性会在 JS 层设置，这里不需要从 props 中提取

  [super updateProps:props oldProps:oldProps];
}

// See RCTParagraphComponentView
- (void)updateState:(const facebook::react::State::Shared &)state oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const RNUITextViewShadowNode::ConcreteState>(state);
  [self setNeedsDisplay];
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return YES;
}

// MARK: - Touch handling

- (CGPoint)getLocationOfPress:(UIGestureRecognizer*)sender
{
  return [sender locationInView:_textView];
}

- (RNUITextViewChild*)getTouchChild:(CGPoint)location
{
  const auto charIndex = [_textView.layoutManager characterIndexForPoint:location
                                                         inTextContainer:_textView.textContainer
                                fractionOfDistanceBetweenInsertionPoints:nil
  ];

  int currIndex = -1;
  for (UIView* child in self.subviews) {
    if (![child isKindOfClass:[RNUITextViewChild class]]) {
      continue;
    }

    RNUITextViewChild* textChild = (RNUITextViewChild*)child;

    // This is UTF16 code units!!
    currIndex += textChild.text.length;

    if (charIndex <= currIndex) {
      return textChild;
    }
  }

  return nil;
}

- (void)handlePressIfNecessary:(UITapGestureRecognizer*)sender
{
  const auto location = [self getLocationOfPress:sender];
  const auto child = [self getTouchChild:location];

  if (child) {
    [child onPress];
  }
}

- (void)handleLongPressIfNecessary:(UILongPressGestureRecognizer*)sender
{
  const auto location = [self getLocationOfPress:sender];
  const auto child = [self getTouchChild:location];

  if (child) {
    [child onLongPress];
  }
  
  // 尝试显示自定义菜单 - 只在手势开始时
  if (sender.state == UIGestureRecognizerStateBegan && self.customMenuItems.count > 0) {
    // 让 textView 成为第一响应者
    [_textView becomeFirstResponder];
    
    // 尝试选择文本（整段文字）
    if (_textView.text.length > 0) {
      UITextPosition *start = [_textView positionFromPosition:_textView.beginningOfDocument offset:0];
      UITextPosition *end = [_textView positionFromPosition:_textView.beginningOfDocument offset:_textView.text.length];
      if (start && end) {
        _textView.selectedTextRange = [_textView textRangeFromPosition:start toPosition:end];
        // Menu is now shown by textView:editMenuForTextInRange:suggestedActions: delegate
      }
    }
  }
}

Class<RCTComponentViewProtocol> RNUITextViewCls(void)
{
  return RNUITextView.class;
}

#pragma mark - Custom Menu Items Methods

// 设置自定义菜单项
- (void)setCustomMenuItems:(NSArray<NSDictionary *> *)customMenuItems {
  NSLog(@"[RNUITextView] setCustomMenuItems: %@", customMenuItems);
  _customMenuItems = customMenuItems;
  
  // 清空现有映射
  [self.menuItemsMap removeAllObjects];
  
  // 为每个自定义菜单项创建唯一的 selector，并动态注册 IMP
  for (NSDictionary *item in customMenuItems) {
    NSString *title = item[@"title"];
    NSString *actionId = item[@"actionId"];
    if (title && actionId) {
      self.menuItemsMap[title] = actionId;
      // 注册 selector
      SEL sel = NSSelectorFromString([NSString stringWithFormat:@"customMenuItemAction_%@:", actionId]);
      if (![self respondsToSelector:sel]) {
        class_addMethod([self class], sel, (IMP)customMenuItemIMP, "v@:@");
      }
    }
  }
  // 更新菜单项（如果已选中）
  // Custom menu is now handled by textView:editMenuForTextInRange:suggestedActions:
}

// C 函数：菜单项 IMP
void customMenuItemIMP(id self, SEL _cmd, id sender) {
  NSString *selName = NSStringFromSelector(_cmd);
  NSString *actionId = [[selName componentsSeparatedByString:@"customMenuItemAction_"].lastObject stringByReplacingOccurrencesOfString:@":" withString:@""];
  if ([self respondsToSelector:@selector(fireCustomMenuActionWithId:)]) {
    [self fireCustomMenuActionWithId:actionId];
  }
}

// 发送事件到 JS
- (void)fireCustomMenuActionWithId:(NSString *)actionId {
  if (actionId && _eventEmitter != nullptr) {
    NSString *selectedText = @"";
    if (_textView.selectedRange.length > 0 && _textView.selectedRange.location != NSNotFound) {
      selectedText = [_textView.text substringWithRange:_textView.selectedRange];
    }
    std::dynamic_pointer_cast<const facebook::react::RNUITextViewEventEmitter>(_eventEmitter)
      ->onCustomMenuAction(facebook::react::RNUITextViewEventEmitter::OnCustomMenuAction{
        static_cast<int>(self.tag),
        std::string([actionId UTF8String]),
        std::string([selectedText UTF8String])
      });
  }
}

// selection 变化时设置自定义菜单项
- (void)textViewDidChangeSelection:(UITextView *)textView {
  NSLog(@"selection changed: range=%@ length=%lu", NSStringFromRange(textView.selectedRange), (unsigned long)textView.selectedRange.length);
  
  // 如果有选中文本，则显示菜单
  if (textView.selectedRange.length > 0) {
    // Menu is now shown by textView:editMenuForTextInRange:suggestedActions: delegate
  }
}

// 开始编辑时
- (void)textViewDidBeginEditing:(UITextView *)textView {
  NSLog(@"textViewDidBeginEditing");
  // 如果有选中文本，则显示菜单
  if (textView.selectedRange.length > 0) {
    // Do nothing here, menu will be shown by textView:editMenuForTextInRange:suggestedActions:
  }
}

#pragma mark - UITextViewDelegate Methods

// Implement the modern API for customizing the edit menu (iOS 13+)
- (UIMenu *)textView:(UITextView *)textView editMenuForTextInRange:(NSRange)range suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions {
    NSLog(@"textView:editMenuForTextInRange: called. Range length: %lu, Custom items: %lu", (unsigned long)range.length, (unsigned long)self.customMenuItems.count);

    // Only show custom menu if text is selected and custom items exist
    if (self.customMenuItems.count == 0 || range.length == 0) {
        // Return an empty menu to hide all system items if no custom items or no selection.
        return [UIMenu menuWithChildren:@[]];
    }

    NSMutableArray<UIMenuElement *> *customActions = [NSMutableArray array];
    for (NSDictionary *item in self.customMenuItems) {
        NSString *title = item[@"title"];
        NSString *actionId = item[@"actionId"];
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"customMenuItemAction_%@:", actionId]);

        if ([self respondsToSelector:selector]) {
            UIAction *uiAction = [UIAction actionWithTitle:title
                                                   image:nil // No image for custom actions for now
                                              identifier:nil // Not strictly needed here
                                                 handler:^(__kindof UIAction * _Nonnull triggeredAction) {
                                                     // Ensure the text view is first responder before performing action
                                                     if (![self->_textView isFirstResponder]) {
                                                         [self->_textView becomeFirstResponder];
                                                     }
                                                     // Perform the custom action
                                                     #pragma clang diagnostic push
                                                     #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                                     [self performSelector:selector withObject:self->_textView]; // Pass textView as a sender context if needed
                                                     #pragma clang diagnostic pop
                                                 }];
            [customActions addObject:uiAction];
            NSLog(@"[RNUITextView] Adding UIAction: '%@' for actionId: '%@'", title, actionId);
        } else {
             NSLog(@"[RNUITextView] Warning: Cannot respond to selector %@ for custom menu item '%@' (actionId: '%@')", NSStringFromSelector(selector), title, actionId);
        }
    }
    
    // Return a menu with only our custom actions.
    // This replaces the entire system menu.
    return [UIMenu menuWithTitle:@"" children:customActions];
}

// 决定哪些菜单项可以显示 - Strictest version
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
  NSString *actionName = NSStringFromSelector(action);
  NSLog(@"[RNUITextView] canPerformAction: %@, selectedRange.length: %lu", actionName, (unsigned long)_textView.selectedRange.length);

  if (_textView.selectedRange.length > 0) {
    // Text is selected. Only allow our custom actions.
    // Deny common system actions to prevent them from appearing in the menu alongside custom items.
    for (NSDictionary *item in self.customMenuItems) {
      NSString *actionId = item[@"actionId"];
      SEL customSel = NSSelectorFromString([NSString stringWithFormat:@"customMenuItemAction_%@:", actionId]);
      if (action == customSel) {
        NSLog(@"[RNUITextView] Allowing custom action: %@", actionName);
        return YES;
      }
    }
    
    // Explicitly deny common system actions when text is selected to try to hide them from the menu.
    // This is because the menu system might still show actions if canPerformAction: returns YES for them,
    // even if they are not in the UIMenu returned by the delegate.
    if (action == @selector(copy:) ||
        action == @selector(cut:) ||
        action == @selector(paste:) ||
        action == @selector(select:) || // Handles 'Select' if it appears
        action == @selector(selectAll:) ||
        action == @selector(delete:) ||
        action == @selector(share:) || // System share, if different from custom (e.g., UIActivityViewController)
        action == NSSelectorFromString(@"promptForReplace:") ||
        action == NSSelectorFromString(@"transliterateChinese:") ||
        action == NSSelectorFromString(@"captureTextFromCamera:") ||
        action == @selector(toggleBoldface:) ||
        action == @selector(toggleItalics:) ||
        action == @selector(toggleUnderline:) ||
        action == @selector(makeTextWritingDirectionLeftToRight:) ||
        action == @selector(makeTextWritingDirectionRightToLeft:) ||
        action == NSSelectorFromString(@"_showTextFormattingOptions:") ||
        action == NSSelectorFromString(@"findSelected:") ||
        action == NSSelectorFromString(@"_findSelected:") ||
        action == NSSelectorFromString(@"addShortcut:") ||
        action == NSSelectorFromString(@"_accessibilitySpeak:") ||
        action == NSSelectorFromString(@"_accessibilitySpeakLanguageSelection:") ||
        action == NSSelectorFromString(@"_accessibilityPauseSpeaking:"))
    {
        NSLog(@"[RNUITextView] Denying system action '%@' explicitly when text is selected to hide from menu.", actionName);
        return NO;
    }

    // For any other unhandled actions when text is selected, deny them to keep the menu clean.
    NSLog(@"[RNUITextView] Denying other unrecognized action '%@' by default when text is selected.", actionName);
    return NO;

  } else {
    // No text is selected.
    // Allow selectAll: so the user can select all text in the text view.
    if (action == @selector(selectAll:)) {
      NSLog(@"[RNUITextView] Allowing selectAll: as no text is selected.");
      return YES;
    }
    // If you wanted to allow pasting into an empty text view, you would allow @selector(paste:) here.
    // For now, deny all other actions if no text is selected.
    NSLog(@"[RNUITextView] Denying action: %@ because no text is selected (and not selectAll).", actionName);
    return NO;
  }
}

// 实现 selectAll: 方法，转发到 _textView
- (void)selectAll:(id)sender {
  [_textView selectAll:sender];
}

// 实现 copy: 方法，转发到 _textView
- (void)copy:(id)sender {
  [_textView copy:sender];
}


// 移除 textViewShouldBeginEditing 和 customMenuItemAction（不再需要，已用 selection 变化和动态 selector 实现）


@end
