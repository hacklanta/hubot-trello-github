# Description:
#
# Dependencies:
#
# Configuration:
#
# Commands:
# 
# Author: 
#   @riveramj

trelloKey = process.env.HUBOT_TRELLO_KEY
trelloToken = process.env.HUBOT_TRELLO_TOKEN
boardId = process.env.HUBOT_TRELLO_BOARD

Trello = require("node-trello")
trelloClient = new Trello(trelloKey, trelloToken)


module.exports = (robot) ->
  userInfoForMsg = (msg,callback) ->
    info = robot.brain.get('trello')?.userInfoByUserId?[msg.message.user.id] || {}
  
    unless info.userId?
      msg.send """
        Do I know you? Try sending me a 'I am <username> in Trello'
        so I know who to look for in Trello!
      """

      callback(null)
    else
      callback(info)


  updateUserInfoForMsg = (msg, updatedFields) ->
    trelloBrain = robot.brain.get('trello') || {}

    trelloBrain.userInfoByUserId ||= {}

    info = (trelloBrain.userInfoByUserId[msg.message.user.id] ||= {})

    info[field] = value for field, value of updatedFields

    robot.brain.set 'trello', trelloBrain

  lookUpUserInfo = (msg, user, callback) ->
    trelloClient.get("/1/members/#{user}", (err, user) =>
      if (err)
        console.log err
        callback? false
      else
        if user.id
          updateUserInfoForMsg msg, userId: user.id
          callback? true
    )


  robot.respond /trello (?:show )?lists/i, (msg) ->
    trelloClient.get("/1/boards/#{boardId}/lists", (err, data) =>
      if (err)
        console.log err
      console.log(data)
    )

  robot.respond /I am ([^ ]+) in Trello/i, (msg) ->
    userName = msg.match[1]
    lookUpUserInfo msg, userName, (foundUser) ->
      if foundUser
        msg.send "Success! I have you as #{userName} in Trello."
      else
        msg.send """
          I couldnt find #{userName} in Trello. 
          Are you sure you have access to this board?
        """

  robot.respond /show my trello cards/i, (msg) ->
    userInfoForMsg msg, (userInfo) ->
      trelloClient.get("/1/boards/#{boardId}/members/#{userInfo.userId}/cards", (err, cards) =>
        if (err)
          console.log err
        for card in cards
          console.log card.name
      )
       

    

