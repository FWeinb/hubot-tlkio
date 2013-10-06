TlkioClient  = require 'tlkio-client',

{Adapter,Robot,TextMessage,EnterMessage,LeaveMessage, User} = require 'hubot'

class TlkIo extends Adapter
  send: (envelope, strings...) ->
    client = @clients[envelope.room] or null
    if client?
      strings.forEach (str) =>
        client.say str

  emote: (envelope, strings...) ->
    @send envelope, "* #{str}" for str in strings

  reply: (envelope, strings...) ->
    strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
    @send envelope, strings...

  run: ->

    # Store all clients ROOM => client
    clients = {};

    rooms = process.env.HUBOT_TLKIO_ROOM.split ','

    # Iterate all rooms and create clients
    rooms.forEach (room) =>
      if room isnt ''
        config =
            room : room
            user :
              nickname:   @robot.name
              avatar  :   process.env.HUBOT_TLKIO_AVATAR

        client = new TlkioClient config

        client.on 'online_participants', (users, guests_count) =>
          users.forEach (user) =>
            hubotUser = @robot.brain.userForId user.id, user
            hubotUser.id   = user.id
            hubotUser.name = user.name

        hubotRegEx = new RegExp '^@'+@robot.name, 'i'

        client.on 'message', (message) =>
          # Normalise text message '@hubot' => 'hubot:'
          message.text = message.text.replace hubotRegEx, @robot.name+':'
          @.receive new TextMessage message.fromUser, message.text, message.id

        client.on 'user_joined', (user) =>
          hubotUser = @robot.brain.userForId user.id, user
          @.receive new EnterMessage user, null

        client.on 'user_left', (user) =>
          hubotUser = @robot.brain.userForId user.id
          @.receive new LeaveMessage hubotUser, null

        # Add this client to the clients
        clients[room] = client

    @clients = clients;

    @.emit 'connected'

exports.use = (robot) ->
  new TlkIo robot
