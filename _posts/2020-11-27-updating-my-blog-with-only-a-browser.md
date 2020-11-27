---
title: Updating my blog with only a browser
excerpt: >-
  The site changes are made available almost immediately.
  It works so well I am finalizing my update here from my phone!
date: '2020-11-27'
thumb_img_path: images/2020-11-27-updating-my-blog-with-only-a-browser.png
content_img_path: images/2020-11-27-updating-my-blog-with-only-a-browser.png
layout: post
---

**Time to put Jekyll to the test!** If this is really as easy as I hoped, I should be able to update my blog with only a web browser. I should even be able to update it from a phone if I really needed to. For this test, I plan on openning a new branch directly from GitHub's online text editor. Once the branch has been opened from the text in this post, I would then hopefully be able to add an additional file directly from the web browser which would be a screenshot of this screen. Getting a screenshot from say a friend or a library computer should be trivial, but in also uploading a picture directly from a phone would also likely be possible.

## Let's start small

I think I will limit the test to just those two items. New text, and a new picture to go with it. So once the new branch has the media I can open a pull request. If I have the opportunity to preview the post it would be preferred but is not required. If you look at the screenshot above there is a Preview option I can use that will show my roughly how the markdown will style the post. The biggest question is will GitHub and Jekyll process the new post markdown and turn it into HTML. If it can't we will fail this test.

## Do did it work?

I guess we will find out here in just a moment. I plan on doing a follow up to the post or simply editing this last paragraph with the results. If I am able to do an in-place edit from the browser as well; I will consider that earning some extra credit. I am pretty optimistic all of this should work though. I mean would someone on the internet really lie like that? Right to my face?!

Update: Well it definitely did not "just work" but not all is lost. I configured a GitHub action that should process this for me. Let's see how it goes...

Update 2: Wow, it works amazingly well! I followed an extremely simple guide on configuring a GitHub action along with a repository secret. Now when I commit changes to my main branch, GitHub spins up a Docker instance and converts my markdown using Jekyll. The site changes are made available almost immediately. It works so well I am finalizing my update here from my phone!
