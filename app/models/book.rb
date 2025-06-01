class Book < ApplicationRecord
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :author, presence: true, length: { minimum: 1, maximum: 255 }
  validates :description, length: { maximum: 1000 }

  # Active Storage 附件
  has_one_attached :cover_image
  has_many_attached :attachments

  # 自定義驗證方法
  validate :cover_image_validation
  validate :attachments_validation

  private

  def cover_image_validation
    return unless cover_image.attached?

    unless cover_image.blob.content_type.in?(%w[image/png image/jpg image/jpeg image/gif])
      errors.add(:cover_image, '封面圖片必須是 PNG, JPG, JPEG 或 GIF 格式')
    end

    if cover_image.blob.byte_size > 5.megabytes
      errors.add(:cover_image, '封面圖片大小不能超過 5MB')
    end
  end

  def attachments_validation
    return unless attachments.attached?

    attachments.each do |attachment|
      unless attachment.blob.content_type.in?(%w[image/png image/jpg image/jpeg image/gif application/pdf text/plain])
        errors.add(:attachments, '附件必須是圖片、PDF 或文字檔案')
        break
      end

      if attachment.blob.byte_size > 10.megabytes
        errors.add(:attachments, '附件大小不能超過 10MB')
        break
      end
    end
  end
end
