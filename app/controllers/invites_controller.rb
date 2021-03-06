class InvitesController < ApplicationController
  def create
    @errors = []
    playlist_id, username = params[:playlist_id], params[:username]
    username.gsub!(/\(.*\)/, '')
    if playlist_id.nil? || username.nil?
      @errors << "ID and Username must present"
    else
      if !Playlist.exists?(:id => playlist_id) || !User.exists?(:username => username)
        @errors << "User or Playlist not found"
      else
        @playlist = Playlist.find(playlist_id)
        @user = User.find_by_username(username)
        unless @playlist.members.collect(&:id).include?(@user.id) || PlaylistInvite.exists?(:playlist_id => playlist_id, :user_id => @user.id)
          @invite = PlaylistInvite.create(:playlist_id => playlist_id,
            :user_id => @user.id,
            :invite_token => BCrypt::Engine.generate_salt)
        else
          @errors << "Already invited"
        end
      end
      respond_to do |format|
        format.js
      end
    end

  end

  def accept
    if params[:token]
      @invite = PlaylistInvite.find_by_invite_token(params[:token])
      if @invite
        @invite.accept(current_user)
        if @invite.errors.length == 0
          redirect_to @invite.playlist, :notice => 'You can collaborate now on this project'
        else
          redirect_to '/', :notice => 'Error occured while accepting invite' + @invite.errors.full_messages.join(', ')
        end
      else
        redirect_to '/', :notice => 'Error occured while accepting invite'
      end
    end
  end

  def generate_for_everyone
    @type = 'link_everyone'
    playlist_id = params[:playlist_id]
    @invite = PlaylistInvite.where(playlist_id: playlist_id, invite_type: @type).first
    unless @invite
      @invite = PlaylistInvite.create(playlist_id: playlist_id, invite_type: @type, invite_token: BCrypt::Engine.generate_salt)
      @created = true
    end

    render :generate
  end

  def generate_for_plisters
    @type = 'link_plisters'
    playlist_id = params[:playlist_id]
    @invite = PlaylistInvite.where(playlist_id: playlist_id, invite_type: @type).first
    unless @invite
      @invite = PlaylistInvite.create(playlist_id: playlist_id, invite_type: @type, invite_token: BCrypt::Engine.generate_salt)
      @created = true
    end

    render :generate
  end

  def autocomplete
    query = params[:query]
    query = "%#{query}%"
    users = User.where(["LOWER(username) LIKE ? or LOWER(name) LIKE ?", query, query])
    resp = {:query => params[:query], :suggestions => [], :data => []}
    users.each do |user|
      resp[:suggestions] << user.username + "(#{user.name})"
      resp[:data] << user.id
    end

    render :text => resp.to_json
  end

end