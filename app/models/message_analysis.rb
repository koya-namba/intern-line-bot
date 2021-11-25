class MessageAnalysis

  def self.analysis(text)
    # 個人メッセージからグループ名，場所と料理を返す
    _, group_name, place_food = text.split("\n")
    place_food = place_food.gsub(" ", ",").gsub("、", ",").gsub("　", ",")
    place, food = place_food.split(",")
    return group_name, place, food
  end

end
