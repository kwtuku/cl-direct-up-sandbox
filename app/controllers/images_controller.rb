class ImagesController < ApplicationController
  # GET /articles/1/images/new
  def new
    @article = Article.find(params[:article_id])
    @image = Image.new
  end

  # GET /articles/1/images/1/edit
  def edit
    @article = Article.find(params[:article_id])
    @image = @article.images.find(params[:id])
  end

  # POST /articles/1/images
  def create
    @article = Article.find(params[:article_id])
    @image = @article.images.new(image_params)

    if @image.save
      redirect_to article_url(@article), notice: '画像を追加しました。'
    else
      render :new
    end
  end

  # PATCH/PUT /articles/1/images/1
  def update
    @article = Article.find(params[:article_id])
    @image = @article.images.find(params[:id])

    if @image.update(image_params)
      redirect_to article_url(@article), notice: '画像を更新しました。'
    else
      render :edit
    end
  end

  # DELETE /articles/1/images/1
  def destroy
    article = Article.find(params[:article_id])
    image = article.images.find(params[:id])
    if image.destroy
      redirect_to article_url(article), notice: '画像を削除しました。'
    else
      redirect_to article_url(article), alert: "画像を削除できません。#{image.errors.map(&:full_message).join('。')}"
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def image_params
    params.require(:image).permit(:cl_id)
  end
end
