# Step-by-Step Guide: Upload to GitHub & Enable GitHub Pages

This guide will help you upload the KICKS-to-Python conversion project to GitHub and enable GitHub Pages for the documentation site.

---

## 📋 Prerequisites

Before you start, make sure you have:

- [ ] A GitHub account ([sign up free at github.com](https://github.com/signup))
- [ ] Git installed on your computer
  - Windows: Download from [git-scm.com](https://git-scm.com/download/win)
  - Mac: Install via Homebrew: `brew install git`
  - Linux: `sudo apt-get install git` (Ubuntu/Debian)
- [ ] The project files (you have these!)

**Choose Your Method:**
- **Method A**: Command Line (Git Bash/Terminal) - Fastest
- **Method B**: GitHub Desktop - Easiest for beginners
- **Method C**: GitHub Web Interface - No software needed

---

## Method A: Upload Using Command Line (Recommended)

### Step 1: Create Repository on GitHub

1. **Go to GitHub** and log in: https://github.com
2. **Click the "+" icon** in the top-right corner
3. **Click "New repository"**
4. **Fill in the details:**
   - **Repository name:** `kicks-to-python` (exactly this name for GitHub Pages to work)
   - **Description:** `Complete conversion of CICS/COBOL applications to Python Flask`
   - **Visibility:** Choose "Public" (required for free GitHub Pages)
   - **Initialize:** ❌ Do NOT check any boxes (no README, .gitignore, or license)
5. **Click "Create repository"**

✅ You'll see a page with instructions - keep this tab open!

### Step 2: Prepare Your Local Repository

Open your terminal/command prompt and navigate to the project directory:

```bash
# Navigate to where you extracted the files
cd /path/to/kicks-to-python

# Or if you're using the GitHub Desktop downloads folder:
cd ~/Downloads/kicks-to-python
```

### Step 3: Initialize Git Repository

```bash
# Initialize git
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: KICKS/COBOL to Python conversion"
```

### Step 4: Connect to GitHub

**Replace `tsiitz` with your actual GitHub username:**

```bash
# Add remote repository
git remote add origin https://github.com/tsiitz/kicks-to-python.git

# Verify it's correct
git remote -v
```

**You should see:**
```
origin  https://github.com/tsiitz/kicks-to-python.git (fetch)
origin  https://github.com/tsiitz/kicks-to-python.git (push)
```

### Step 5: Push to GitHub

```bash
# Push to GitHub
git push -u origin main
```

**If you get an error about 'main' vs 'master':**

```bash
# Rename branch to main if needed
git branch -M main

# Then push again
git push -u origin main
```

**If asked for credentials:**
- **Username:** Your GitHub username
- **Password:** Use a **Personal Access Token** (not your GitHub password)
  - Go to: GitHub Settings → Developer settings → Personal access tokens → Generate new token
  - Select scopes: `repo`, `workflow`
  - Copy the token and paste it as your password

✅ **Success!** Your code is now on GitHub!

### Step 6: Enable GitHub Pages

**In your web browser:**

1. **Go to your repository:** `https://github.com/tsiitz/kicks-to-python`
2. **Click "Settings"** (tab near the top)
3. **Click "Pages"** (left sidebar)
4. **Under "Source":**
   - Select **Branch:** `main`
   - Select **Folder:** `/docs`
   - Click **"Save"**
5. **Wait 1-2 minutes** for GitHub to build your site
6. **Refresh the page** - you'll see a green box with your URL

✅ **Your documentation site is live!**

**Your GitHub Pages URL will be:**
```
https://tsiitz.github.io/kicks-to-python/
```

### Step 7: Update README with Your URL

Now update the README files with your actual GitHub username:

```bash
# Open README.md and replace tsiitz with your actual username
# Do this in docs/index.md as well

# Then commit and push the changes
git add README.md docs/index.md
git commit -m "Update documentation URLs"
git push
```

---

## Method B: Upload Using GitHub Desktop (Easiest)

### Step 1: Install GitHub Desktop

1. **Download GitHub Desktop:** https://desktop.github.com/
2. **Install** and **sign in** with your GitHub account

### Step 2: Create Repository on GitHub

1. **Go to GitHub** and log in: https://github.com
2. **Click the "+" icon** → "New repository"
3. **Repository name:** `kicks-to-python`
4. **Description:** `Complete conversion of CICS/COBOL applications to Python Flask`
5. **Public** repository
6. **Do NOT initialize** with README, .gitignore, or license
7. **Click "Create repository"**

### Step 3: Add Repository in GitHub Desktop

1. **Open GitHub Desktop**
2. **File** → **Add Local Repository**
3. **Choose** the `kicks-to-python` folder
4. **If asked to create a repository,** click "Create repository"

### Step 4: Make Initial Commit

1. **You'll see all files listed** in the left panel
2. **Bottom left:** Enter commit message: `Initial commit: KICKS/COBOL to Python conversion`
3. **Click "Commit to main"**

### Step 5: Publish to GitHub

1. **Click "Publish repository"** (top right)
2. **Uncheck "Keep this code private"** (required for GitHub Pages)
3. **Click "Publish repository"**

✅ **Done!** Your code is now on GitHub!

### Step 6: Enable GitHub Pages

Follow the same instructions as **Method A, Step 6** above.

---

## Method C: Upload via GitHub Web Interface

### Step 1: Create Repository

1. **Go to GitHub:** https://github.com
2. **Sign in** to your account
3. **Click "+"** → "New repository"
4. **Name:** `kicks-to-python`
5. **Public** repository
6. **Check "Add a README file"**
7. **Click "Create repository"**

### Step 2: Upload Files

1. **Click "Add file"** → "Upload files"
2. **Drag and drop** all files from your `kicks-to-python` folder
   - **Important:** Upload everything including the `docs/` folder
3. **Commit message:** `Initial commit: KICKS/COBOL to Python conversion`
4. **Click "Commit changes"**

⚠️ **Note:** This method has a file size limit. If you get errors, use Method A or B instead.

### Step 3: Enable GitHub Pages

Follow **Method A, Step 6** above.

---

## 🎨 Customizing Your Documentation

### Update URLs in Documentation

After your repository is created, update these files with your GitHub username:

**Files to update:**
1. `README.md` - Line 10, 203, 251, 261
2. `docs/index.md` - Multiple locations

**Find and replace:**
- Find: `tsiitz`
- Replace: `your-actual-github-username`

**Using command line:**
```bash
# On Mac/Linux:
sed -i '' 's/tsiitz/your-actual-username/g' README.md
sed -i '' 's/tsiitz/your-actual-username/g' docs/index.md

# On Linux (no quotes):
sed -i 's/tsiitz/your-actual-username/g' README.md
sed -i 's/tsiitz/your-actual-username/g' docs/index.md

# Then commit and push:
git add .
git commit -m "Update documentation URLs"
git push
```

### Add Your Name to LICENSE

Edit the `LICENSE` file and replace `[Your Name]` with your actual name.

---

## 🎯 Verify Everything Works

### Check Your Repository

Visit: `https://github.com/tsiitz/kicks-to-python`

You should see:
- ✅ All files uploaded
- ✅ README displays correctly
- ✅ Green "Public" badge
- ✅ Description shows

### Check GitHub Pages

Visit: `https://tsiitz.github.io/kicks-to-python/`

You should see:
- ✅ Nice documentation site with theme
- ✅ All content displays correctly
- ✅ Links work
- ✅ Navigation works

**If GitHub Pages isn't working:**
- Wait 2-5 minutes and refresh
- Check Settings → Pages shows green success message
- Verify source is set to `main` branch and `/docs` folder

---

## 🔄 Making Updates Later

### Using Command Line

```bash
# Make your changes to files

# Check what changed
git status

# Add changed files
git add .

# Commit with a message
git commit -m "Description of your changes"

# Push to GitHub
git push
```

### Using GitHub Desktop

1. **Make changes** to files
2. **GitHub Desktop** will show changes automatically
3. **Enter commit message** and **click "Commit to main"**
4. **Click "Push origin"**

### Using GitHub Web

1. **Navigate to file** in GitHub
2. **Click pencil icon** (Edit)
3. **Make changes**
4. **Click "Commit changes"**

---

## 🐛 Troubleshooting

### "Permission denied" when pushing

**Solution:** Use a Personal Access Token instead of password:
1. GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select `repo` scope
4. Copy token and use as password when pushing

### GitHub Pages shows 404

**Solutions:**
1. **Wait 2-5 minutes** - GitHub Pages takes time to build
2. **Check Settings → Pages** - Verify source is `/docs` folder
3. **Check docs/_config.yml exists**
4. **Verify docs/index.md exists**

### Files not uploading

**Solutions:**
1. **Check file size** - GitHub has 100MB limit per file
2. **Remove mainframe.db** if present (it's in .gitignore)
3. **Use command line method** if web upload fails

### "Repository already exists"

**Solution:**
1. Delete the repository on GitHub
2. Wait 5 minutes
3. Try creating again with same name

---

## ✅ Checklist

After completing all steps, verify:

- [ ] Repository created on GitHub
- [ ] All files uploaded (check on GitHub.com)
- [ ] README displays correctly on repository page
- [ ] GitHub Pages enabled (Settings → Pages)
- [ ] Documentation site accessible at tsiitz.github.io/kicks-to-python
- [ ] URLs updated with your actual username
- [ ] LICENSE has your name
- [ ] Repository is Public (for GitHub Pages)

---

## 🎉 You're Done!

Your project is now live on GitHub with documentation on GitHub Pages!

**Share your work:**
- Repository URL: `https://github.com/tsiitz/kicks-to-python`
- Documentation: `https://tsiitz.github.io/kicks-to-python/`

**Next steps:**
- Add screenshots to `docs/images/` folder
- Customize the documentation
- Add your own programs
- Share with the community

---

## 📞 Need Help?

If you run into issues:

1. **Check this guide again** - Re-read the relevant section
2. **GitHub Docs:** https://docs.github.com/en/pages
3. **Git Docs:** https://git-scm.com/doc
4. **Stack Overflow:** Search for your error message

**Common Issues:**
- Authentication: Use Personal Access Token, not password
- GitHub Pages 404: Wait a few minutes, check Settings → Pages
- Large files: Remove database files (in .gitignore already)

---

**Happy coding! 🚀**
