class LikesController < ApplicationController
  before_filter :restrict_access, except: :index

  def create
    post = Post.find(params.require(:id))
    Like.like(@authenticated_user, post)
    render json: {success: true}, status: :created
  end

  def index
    post = Post.find(params.require(:id))
    response = {
      success: true,
      result: post.likes
    }
    render json: response, status: :ok
  end
end
