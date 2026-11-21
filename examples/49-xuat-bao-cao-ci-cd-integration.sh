# Xuất SARIF (tích hợp GitHub Code Scanning / GitLab)
docker scout cves --format sarif --output report.sarif.json todo-image

# Xuất SBOM định dạng SPDX
docker scout sbom --format spdx todo-image > sbom.spdx.json
