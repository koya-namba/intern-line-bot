class MessageAnalysis

    def self.analysis(text)
        # 個人メッセージから場所と料理を返す
        text = text.gsub(" ", ",").gsub("、", ",").gsub("　", ",")
        place, food = text.split(",")
    end

end
