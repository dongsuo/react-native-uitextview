import React from 'react'
import {
  Platform,
  StyleSheet,
  Text as RNText,
  type TextProps,
  type ViewStyle,
} from 'react-native'

// 自定义菜单项接口
interface CustomMenuItem {
  title: string
  actionId: string
}

// 自定义菜单事件接口
interface CustomMenuActionEvent {
  actionId: string
  selectedText: string
}
import RNUITextViewChildNativeComponent from './RNUITextViewChildNativeComponent'
import RNUITextViewNativeComponent from './RNUITextViewNativeComponent'
import {flattenStyles} from './util'

const TextAncestorContext = React.createContext<[boolean, ViewStyle]>([
  false,
  StyleSheet.create({}),
])

const textDefaults: TextProps = {
  allowFontScaling: true,
  selectable: true,
}

const useTextAncestorContext = () => React.useContext(TextAncestorContext)

// 扩展 TextProps 类型添加自定义菜单相关属性
type ExtendedTextProps = TextProps & {
  uiTextView?: boolean
  customMenuItems?: CustomMenuItem[]
  onCustomMenuAction?: (event: CustomMenuActionEvent) => void
}

function UITextViewChild({
  style,
  children,
  customMenuItems,
  onCustomMenuAction,
  ...rest
}: ExtendedTextProps) {
  const [isAncestor, rootStyle] = useTextAncestorContext()

  // Flatten the styles, and apply the root styles when needed
  const flattenedStyle = React.useMemo(
    () => flattenStyles(rootStyle, style),
    [rootStyle, style],
  )
  console.log('customMenuItems', customMenuItems)
  if (!isAncestor) {
    return (
      <TextAncestorContext.Provider value={[true, flattenedStyle]}>
        <RNUITextViewNativeComponent
          {...textDefaults}
          {...rest}
          // ellipsizeMode={rest.ellipsizeMode ?? rest.lineBreakMode ?? 'tail'}
          style={[flattenedStyle]}
          // 自定义菜单相关属性
          customMenuItems={customMenuItems}
          onCustomMenuAction={event => {
            onCustomMenuAction &&
              onCustomMenuAction({
                actionId: event.nativeEvent.actionId,
                selectedText: event.nativeEvent.selectedText,
              })
          }}
          // @ts-expect-error Weirdness
          onPress={undefined}
          onLongPress={undefined}>
          {React.Children.toArray(children).map((c, index) => {
            if (React.isValidElement(c)) {
              return c
            } else if (typeof c === 'string' || typeof c === 'number') {
              return (
                // @ts-expect-error @TODO fix this type
                <RNUITextViewChildNativeComponent
                  key={index}
                  style={flattenedStyle}
                  text={c.toString()}
                  {...rest}
                />
              )
            }
            return null
          })}
        </RNUITextViewNativeComponent>
      </TextAncestorContext.Provider>
    )
  } else {
    return (
      <>
        {React.Children.toArray(children).map((c, index) => {
          if (React.isValidElement(c)) {
            return c
          } else if (typeof c === 'string' || typeof c === 'number') {
            return (
              // @ts-expect-error @TODO fix this type
              <RNUITextViewChildNativeComponent
                key={index}
                style={flattenedStyle}
                text={c.toString()}
                {...rest}
              />
            )
          }

          return null
        })}
      </>
    )
  }
}

function UITextViewInner(props: ExtendedTextProps) {
  const [isAncestor] = useTextAncestorContext()

  // Even if the uiTextView prop is set, we can still default to using
  // normal selection (i.e. base RN text) if the text doesn't need to be
  // selectable
  if ((!props.selectable || !props.uiTextView) && !isAncestor) {
    // 当使用原生 RNText 时，自定义菜单功能不可用
    // Using _ prefix to indicate these are intentionally unused
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const {customMenuItems: _, onCustomMenuAction: __, ...restProps} = props
    return <RNText {...restProps} />
  }
  return <UITextViewChild {...props} />
}

export function UITextView(props: ExtendedTextProps) {
  if (Platform.OS !== 'ios') {
    // 当不是 iOS 平台时，自定义菜单功能不可用
    // Using _ prefix to indicate these are intentionally unused
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const {customMenuItems: _, onCustomMenuAction: __, ...restProps} = props
    return <RNText {...restProps} />
  }
  return <UITextViewInner {...props} />
}
