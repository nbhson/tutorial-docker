# Tổng quan nhanh về vulnerability của image (dùng image build gần nhất nếu không chỉ định)
docker scout quickview todo-image:multi-stage
#   ✓ SBOM of image already cached, 187 packages indexed
#   Your image  todo-image:multi-stage  │  0C  2H  8M  1L
#   Base image  node:22-alpine          │  0C  0H  0M  0L

# Liệt kê chi tiết CVEs
docker scout cves todo-image:multi-stage

# Chỉ hiện CVE có thể fix được
docker scout cves --only-fixed todo-image:multi-stage

# Lọc theo mức độ nghiêm trọng
docker scout cves --only-severity critical,high todo-image:multi-stage

# Lọc CVE theo package cụ thể (ví dụ express)
docker scout cves --only-package express

# Xuất SBOM của image
docker scout sbom todo-image:multi-stage

# Gợi ý update base image để giảm CVE
docker scout recommendations todo-image:multi-stage

# So sánh 2 image (trước/sau khi fix)
docker scout compare todo-image:1.0 --to todo-image:2.0

# Thoát mã 2 nếu có vulnerability (dùng trong CI/CD)
docker scout cves --exit-code --only-severity critical,high todo-image:multi-stage
