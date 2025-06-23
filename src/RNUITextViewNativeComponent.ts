import codegenNativeComponent from "react-native/Libraries/Utilities/codegenNativeComponent";
import type { ViewProps } from "react-native";
import type {
  BubblingEventHandler,
  Int32,
  WithDefault,
  DirectEventHandler,
} from "react-native/Libraries/Types/CodegenTypes";

interface TargetedEvent {
  target: Int32;
}

interface TextLayoutEvent extends TargetedEvent {
  lines: string[];
}

// 自定义菜单项接口
interface CustomMenuItem {
  title: string;
  actionId: string;
}

// 自定义菜单操作事件
interface CustomMenuActionEvent extends TargetedEvent {
  actionId: string;
  selectedText: string;
}

type EllipsizeMode = "head" | "middle" | "tail" | "clip";

interface NativeProps extends ViewProps {
  // 现有属性
  numberOfLines?: Int32;
  allowFontScaling?: WithDefault<boolean, true>;
  ellipsizeMode?: WithDefault<EllipsizeMode, "tail">;
  selectable?: boolean;
  onTextLayout?: BubblingEventHandler<TextLayoutEvent>;

  // 新增自定义菜单属性
  customMenuItems?: ReadonlyArray<CustomMenuItem>;
  onCustomMenuAction?: DirectEventHandler<CustomMenuActionEvent>;
}

export default codegenNativeComponent<NativeProps>("RNUITextView", {
  excludedPlatforms: ["android"],
});
