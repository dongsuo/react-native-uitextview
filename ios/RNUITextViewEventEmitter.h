#pragma once

#include <react/renderer/components/view/ViewEventEmitter.h>

namespace facebook::react {

class RNUITextViewEventEmitter : public ViewEventEmitter {
 public:
  using ViewEventEmitter::ViewEventEmitter;

  struct OnTextLayout {
    int target;
    std::vector<std::string> lines;
  };
  
  struct OnCustomMenuAction {
    int target;
    std::string actionId;
    std::string selectedText;
  };

  void onTextLayout(OnTextLayout value) const;
  void onCustomMenuAction(OnCustomMenuAction value) const;
};

} // namespace facebook::react
