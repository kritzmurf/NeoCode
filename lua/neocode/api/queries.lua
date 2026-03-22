local M = {}

M.GLOBAL_DATA = [[
query globalData {
  userStatus {
    userId
    isSignedIn
    username
    realName
    avatar
    activeSessionId
  }
}
]]

M.QUESTION_DATA = [[
query questionData($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    questionId
    questionFrontendId
    title
    titleSlug
    content
    difficulty
    topicTags {
      name
      slug
    }
    codeSnippets {
      lang
      langSlug
      code
    }
    exampleTestcaseList
    sampleTestCase
    metaData
  }
}
]]

M.PROBLEMSET_QUESTION_LIST = [[
query problemsetQuestionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
  problemsetQuestionList: questionList(
    categorySlug: $categorySlug
    limit: $limit
    skip: $skip
    filters: $filters
  ) {
    total: totalNum
    questions: data {
      acRate
      difficulty
      freqBar
      frontendQuestionId: questionFrontendId
      isFavor
      paidOnly: isPaidOnly
      status
      title
      titleSlug
      topicTags {
        name
        slug
      }
    }
  }
}
]]

M.DAILY_QUESTION = [[
query questionOfToday {
  activeDailyCodingChallengeQuestion {
    date
    link
    question {
      questionFrontendId
      title
      titleSlug
      difficulty
    }
  }
}
]]

return M
