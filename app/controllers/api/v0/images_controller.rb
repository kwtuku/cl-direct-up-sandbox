module Api
  module V0
    class ImagesController < ApplicationController
      def destroy
        article = Article.find(params[:article_id])
        image = article.images.find(params[:id])
        if image.destroy
          render json: { message: 'Deleted image' }, status: :ok
        else
          render json: { message: 'Cannot delete image' }, status: :unprocessable_entity
        end
      end
    end
  end
end
