TlkioClient  = require './tlkio-client',
Readline     = require 'readline'

{Adapter,Robot,TextMessage,EnterMessage,LeaveMessage, User} = require 'hubot'

class TlkIo extends Adapter
  send: (envelope, strings...) ->
    strings.forEach (str) =>
      @client.say str

  emote: (envelope, strings...) ->
    @send envelope, "* #{str}" for str in strings

  reply: (envelope, strings...) ->
    strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
    @send envelope, strings...

  run: ->
    self = @

    config =
        channel :  process.env.HUBOT_TLKIO_CHANNEL
        user :
          nickname:   process.env.HUBOT_TLKIO_NICKNAME or @robot.name
          avatar  :   process.env.HUBOT_TLKIO_AVATAR

    client = new TlkioClient config


    client.on 'online_participants', (users, guests_count) =>
      users.forEach (user) =>
        hubotUser = @robot.brain.userForId user.id, user
        hubotUser.id   = user.id
        hubotUser.name = user.name

    client.on 'textmessage', (message) =>
      @.receive new TextMessage message.fromUser, message.text, message.id

    client.on 'user_joined', (user) =>
      hubotUser = @robot.brain.userForId user.id, user
      @.receive new EnterMessage user, null

    client.on 'user_left', (user) =>
      hubotUser = @robot.brain.userForId user.id
      @.receive new LeaveMessage hubotUser, null


    @client = client;

    @.emit 'connected'

exports.use = (robot) ->
  new TlkIo robot
