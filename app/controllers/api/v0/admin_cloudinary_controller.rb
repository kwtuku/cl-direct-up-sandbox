module Api
  module V0
    class AdminCloudinaryController < ApplicationController
      def destroy
        if Image.exists?(['cl_id LIKE ?', "%#{Image.sanitize_sql_like(params[:id])}%"])
          render json: { message: 'Cannot delete image' }, status: :forbidden
          return
        end

        response = Cloudinary::Uploader.destroy(params[:id])
        if response['result'] == 'ok'
          render json: { message: 'Deleted image' }, status: :ok
        else
          render json: { message: 'Cannot delete image' }, status: :unprocessable_entity
        end
      end
    end
  end
end
