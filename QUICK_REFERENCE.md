# Quick Reference Card - GitHub Upload

## 🚀 Fastest Method (Command Line)

```bash
# 1. Navigate to project folder
cd ~/Downloads/kicks-to-python

# 2. Initialize and commit
git init
git add .
git commit -m "Initial commit: KICKS/COBOL to Python conversion"

# 3. Create repo on GitHub.com (kicks-to-python, Public)

# 4. Connect and push 
git remote add origin https://github.com/tsiitz/kicks-to-python.git
git push -u origin main

# 5. Enable GitHub Pages:
#    GitHub.com → Settings → Pages → Source: main branch, /docs folder

# 6. Update URLs in README.md and docs/index.md
#    Replace tsiitz with your actual username

# 7. Push updates
git add .
git commit -m "Update documentation URLs"
git push
```

## 🌐 Your Links

After upload, your project will be at:

- **Repository:** https://github.com/tsiitz/kicks-to-python
- **Documentation:** https://tsiitz.github.io/kicks-to-python/
- **Python App:** Clone and run `python app.py` → http://localhost:5000

## ✅ Verification Checklist

- [ ] Repository created on GitHub
- [ ] All files visible on GitHub
- [ ] GitHub Pages enabled (Settings → Pages → green success message)
- [ ] Documentation site loads (may take 2-5 minutes)
- [ ] README displays correctly
- [ ] URLs updated with your username

## 🎯 Sample Data

After running `python app.py`, use these to test:

- **Customer Numbers:** 400001, 400002, 400003
- **Product Codes:** 0000000001, 0000000005

## 🐛 Quick Troubleshooting

**Permission denied?**
→ Use Personal Access Token (GitHub Settings → Developer settings → Tokens)

**GitHub Pages 404?**
→ Wait 2-5 minutes, check Settings → Pages

**Can't push large files?**
→ Database file is already in .gitignore (won't be uploaded)

---

**Full Instructions:** See GITHUB_UPLOAD_INSTRUCTIONS.md
