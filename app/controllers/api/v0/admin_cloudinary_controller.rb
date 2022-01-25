module Api
  module V0
    class AdminCloudinaryController < ApplicationController
      def destroy
        if Image.exists?(['cl_id LIKE ?', "%#{Image.sanitize_sql_like(params[:public_id])}%"])
          render json: { message: 'forbidden' }, status: :forbidden
          return
        end

        response = Cloudinary::Uploader.destroy(params[:public_id])
        if response['result'] == 'ok'
          render json: { message: 'ok' }, status: :ok
        else
          render json: { message: 'unprocessable entity' }, status: :unprocessable_entity
        end
      end
    end
  end
end
