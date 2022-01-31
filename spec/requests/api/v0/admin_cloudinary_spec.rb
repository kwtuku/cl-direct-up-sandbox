require 'rails_helper'

RSpec.describe 'Api::V0::AdminCloudinary', type: :request do
  describe 'DELETE /api/v0/admin_cloudinary/:public_id' do
    context 'when image exists' do
      it 'returns forbidden' do
        public_id = create(:image).cl_id_identifier.split(%r{[/|.]})[0]
        delete api_v0_admin_cloudinary_path(public_id)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when cloudinary response is ok' do
      it 'returns ok' do
        allow(Cloudinary::Uploader).to receive(:destroy).and_return({ 'result' => 'ok' })

        public_id = SecureRandom.hex(10)
        delete api_v0_admin_cloudinary_path(public_id)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when cloudinary response is not ok' do
      it 'returns unprocessable_entity' do
        allow(Cloudinary::Uploader).to receive(:destroy).and_return({ 'result' => 'not found' })

        public_id = SecureRandom.hex(10)
        delete api_v0_admin_cloudinary_path(public_id)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
