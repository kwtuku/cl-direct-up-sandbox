class ArticlesController < ApplicationController
  before_action :set_article, only: %i[show edit update destroy]

  # GET /articles
  def index
    @articles = Article.eager_load(:images)
  end

  # GET /articles/1
  def show; end

  # GET /articles/new
  def new
    @article_form = ArticleForm.new
  end

  # GET /articles/1/edit
  def edit
    @article_form = ArticleForm.new(article: @article)
  end

  # POST /articles
  def create
    @article_form = ArticleForm.new(article_params)

    if @article_form.save
      redirect_to @article_form, notice: '記事を作成しました。'
    else
      render :new
    end
  end

  # PATCH/PUT /articles/1
  def update
    @article_form = ArticleForm.new(article_params, article: @article)

    if @article_form.save
      redirect_to @article_form, notice: '記事を更新しました。'
    else
      render :edit
    end
  end

  # DELETE /articles/1
  def destroy
    @article.destroy
    redirect_to articles_url, notice: '記事を削除しました。'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def article_params
    params.require(:article).permit(:title, :body, cl_ids: [], image_attributes: %i[id cl_id _destroy])
  end
end
