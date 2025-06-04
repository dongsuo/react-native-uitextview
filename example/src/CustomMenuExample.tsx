import {View, StyleSheet, Alert, SafeAreaView} from 'react-native'
import {UITextView} from '@dongsuo/react-native-uitextview'

// 自定义菜单示例组件
const CustomMenuExample = () => {
  // 处理自定义菜单动作
  const handleCustomMenuAction = (event: {
    actionId: string
    selectedText: string
  }) => {
    const {actionId, selectedText} = event

    switch (actionId) {
      case 'translate':
        Alert.alert('翻译', `将要翻译: "${selectedText}"`)
        break
      case 'share':
        Alert.alert('分享', `将要分享: "${selectedText}"`)
        break
      case 'search':
        Alert.alert('搜索', `将要搜索: "${selectedText}"`)
        break
      default:
        break
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.textContainer}>
        <UITextView
          style={styles.text}
          uiTextView={true}
          selectable={true}
          // 自定义菜单项配置
          customMenuItems={[
            {title: '翻译', actionId: 'translate'},
            {title: '分享', actionId: 'share'},
            {title: '搜索', actionId: 'search'},
          ]}
          // 菜单项点击事件处理
          onCustomMenuAction={handleCustomMenuAction}>
          这是一个带有自定义菜单的文本示例。长按这段文字来查看自定义菜单选项。
          您可以选择翻译、分享或搜索选定的文本。
        </UITextView>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  textContainer: {
    padding: 20,
  },
  text: {
    fontSize: 16,
    lineHeight: 24,
  },
})

export default CustomMenuExample
