# Seat: UI/UX expert

Judge every screen in the pack as a UI/UX lead on a tactics game. Read docs/playbooks/screens.md first: it holds the
approved screen designs and Ryan's picks; reopening one is "reopen: Ryan's call", not a bug. The Neon front-end UI audit
(Nov 19, /mnt/project-files/audits/neon_frontend_ui_1119.md) is prior art: build on it, do not repeat it.

Look for: information the player needs and cannot find; information shown that nobody needs; reading order and hierarchy;
contrast and text size (normal and larger text); consistency of buttons, icons, colours and words across screens; feedback
after every action (hover, selected, disabled, why disabled); turn flow cost (clicks per common action); onboarding and
teaching cards; error and empty states; controller and keyboard paths if any; anything that breaks at the larger text size.

Write `legs/<model>_ui_ux.md`: up to 15 findings, worst first, each with the screen and picture name, what is wrong, who
feels it and when, and a proposed fix. Then up to 5 things that are good and must be kept.
