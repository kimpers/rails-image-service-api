class UsersController < ApplicationController
  include Pagingable
  before_filter :restrict_access, except: [:sign_up, :log_in, :feed]
  def sign_up
    user = User.new(signup_params)
    if user.save
      response = {success: true, result: user.id}
      render json: response, status: :created
    else
      response = {success: false}
      render json: response, status: :internal_server_error
    end
  end

  def log_in
    params =  login_params
    token = User.authenticate(params['username'], params['password'])
    if token
      response = {success: true, result: token}
      render json: response, status: :ok
    else
      response = {success: false}
      render json: response, status: :unauthorized
    end
  end

  def show
    user = User.find(params.require(:id))
    response = { success: true, result: UserSerializer.new(user, root: false) }
    render json: response , status: :ok
  end

  def index
    offset, limit = pagination_values
    users = User.order(:id).offset(offset).limit(limit)
    response = {success: true, result: ActiveModel::ArraySerializer.new(users, each_serializer: UserSerializer, root: false), offset: offset, limit: limit}
    render json: response , status: :ok
  end

  def following
    offset, limit = pagination_values
    user = User.find(params.require(:id))
    response = {
      success: true,
      offset: offset,
      limit: limit,
      result: ActiveModel::ArraySerializer.new(user.followings.offset(offset).limit(limit), each_serializer: UserFollowSerializer, root:false)
    }
    render json: response, status: :ok
  end

  def followers
    offset, limit = pagination_values
    user = User.find(params.require(:id))
    response = {
      success: true,
      offset: offset,
      limit: limit,
      result: ActiveModel::ArraySerializer.new(user.followers.offset(offset).limit(limit), each_serializer: UserFollowSerializer, root: false)
    }
    render json: response , status: :ok
  end

  def following_posts
    offset, limit = pagination_values
    following_ids = UserFollowing.where(user_id: id).pluck(:following_id)
    posts = Post.select(:id, :description, :author_id, :created_at).where(author: following_ids).order(created_at: :desc).offset(offset).limit(limit)
    response = {
      success: true,
      offset: offset,
      limit: limit,
      result: ActiveModel::ArraySerializer.new(posts, each_serializer: PostSerializer, root: false)
    }
    render json: response, status: :ok
  end

  def followers_posts
    offset, limit = pagination_values
    id = params.require(:id)
    follower_ids = UserFollowing.where(following_id: id).pluck(:user_id)
    follower_posts = Post.select(:id, :description, :author_id, :created_at).where(author: follower_ids).order(created_at: :desc).offset(offset).limit(limit)
    response = {
      success: true,
      offset: offset,
      limit: limit,
      result: ActiveModel::ArraySerializer.new(follower_posts, each_serializer: PostSerializer, root: false)
    }
    render json: response, status: :ok
  end

  # A user's feed is all posts made by that user or any of the users it follows
  # ordered by time of posting
  def feed
    offset, limit = pagination_values
    id = User.find(params.require(:id))
    feed_users_ids = UserFollowing.where(user_id: id).pluck(:following_id) << id
    feed_posts = Post.select(:id, :description, :author_id, :created_at).where(author: feed_users_ids).order(created_at: :desc).offset(offset).limit(limit)
    response = {
      success: true,
      offset: offset,
      limit: limit,
      result: ActiveModel::ArraySerializer.new(feed_posts, each_serializer: PostSerializer, root: false)
    }
    render json: response, status: :ok
  end

  private
  def login_params
    params.permit(:username, :password)
  end

  def signup_params
    params.permit(:username, :email, :password, :birthdate, :description, :gender)
  end
end
