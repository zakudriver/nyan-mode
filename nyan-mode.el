;;; nyan-mode.el --- Nyan Cat shows position in current buffer in mode-line  -*- lexical-binding: t; -*-

;; Nyanyanyanyanyanyanya!

;; Author: Jacek "TeMPOraL" Zlydach <temporal.pl@gmail.com>
;; URL: https://github.com/TeMPOraL/nyan-mode/
;; Version: 1.1.4
;; Keywords: convenience, games, mouse, multimedia
;; Nyanwords: nyan, cat, lulz, scrolling, pop tart cat, build something amazing
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;; ...yet. ;).

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; NEW! You can now click on the rainbow (or the empty space)
;; to scroll your buffer!

;; NEW! You can now customize the minimum window width
;; below which the nyan-mode will be disabled, so that more important
;; information can be shown in the modeline.

;; To activate, just load and put `(nyan-mode 1)' in your init file.

;; Contributions and feature requests welcome!

;; Inspired by (and in few places copied from) sml-modeline.el written by Lennart Borgman.
;; See: http://bazaar.launchpad.net/~nxhtml/nxhtml/main/annotate/head%3A/util/sml-modeline.el

;;; History:

;; 2016-04-26 - introduced click-to-scroll feature.

;; Started as a totally random idea back in August 2011.

;; The homepage at http://nyan-mode.buildsomethingamazing.com died somewhen in 2014/2015 because reasons.
;; I might get the domain back one day.

;;; Code:


(defgroup nyan nil
  "Customization group for `nyan-mode'."
  :group 'frames)


(defun nyan-refresh ()
  "Refresh nyan mode.
Intended to be called when customizations were changed, to
reapply them immediately."
  (when (featurep 'nyan-mode)
    (when (and (boundp 'nyan-mode)
               nyan-mode)
      (nyan-mode -1)
      (nyan-mode 1))))


(defcustom nyan-animation-frames 10
  "Nyan animation frames."
  :type 'float
  :set (lambda (sym val)
         (set-default sym val)
         (nyan-refresh))
  :group 'nyan)


(defcustom nyan-minimum-window-width 64
  "Minimum width of the window, below which nyan-mode will not be displayed.
This is important because nyan-mode will push out all
informations from small windows."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (nyan-refresh))
  :group 'nyan)


;;; FIXME bug, doesn't work for antoszka.
(defcustom nyan-wavy-trail nil
  "If enabled, Nyan Cat's rainbow trail will be wavy."
  :type '(choice (const :tag "Enabled" t)
                 (const :tag "Disabled" nil))
  :set (lambda (sym val)
         (set-default sym val)
         (nyan-refresh))
  :group 'nyan)

(defcustom nyan-bar-length 32
  "Length of Nyan Cat bar in units.
Each unit is equal to an 8px image.
Minimum of 3 units are required for Nyan Cat."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (nyan-refresh))
  :group 'nyan)


(defcustom nyan-animate-nyancat nil
  "Enable animation for Nyan Cat.
This can be t or nil."
  :type '(choice (const :tag "Enabled" t)
                 (const :tag "Disabled" nil))
  ;; FIXME: Starting an animation timer on defcustom isn't a good idea; this needs to, at best, maybe start/stop a timer iff the mode is on,
  ;; otherwise just set a flag. -- Jacek Złydach, 2020-05-26
  ;; :set (lambda (sym val)
  ;;        (set-default sym val)
  ;;        (if val
  ;;            (nyan-start-animation)
  ;;          (nyan-stop-animation))
  ;;        (nyan-refresh))
  :group 'nyan)


(defcustom nyan-cat-face-number 1
  "Select cat face number for console."
  :type 'integer
  :group 'nyan)


(defcustom nyan-cat-flavor 'original
  "Pick a nyan flavor."
  :group 'nyan
  :type '(choice
          (const :tag "Original cat" original)
          (const :tag "Jazz cat" jazz)
          (const :tag "Gba Game cat" gb)
          (const :tag "Pikachu cat" pikanyan)))

;;; Constants

(defconst nyan-directory (file-name-directory (or load-file-name buffer-file-name)))

(defconst nyan-cat-size 6)

(defconst nyan-music (concat nyan-directory "mus/nyanlooped.mp3"))

(defconst nyan-modeline-help-string "Nyanyanya!\nmouse-1: Scroll buffer position")

(defconst nyan-flavor-list '(original jazz gb pikanyan))

(defconst nyan-cat-face [
                         ["[]*" "[]#"]
                         ["(*^ｰﾟ)" "( ^ｰ^)" "(^ｰ^ )" "(ﾟｰ^*)"]
                         ["(´ω｀三 )" "( ´ω三｀ )" "( ´三ω｀ )" "( 三´ω｀)"
                          "( 三´ω｀)" "( ´三ω｀ )" "( ´ω三｀ )" "(´ω｀三 )"]
                         ["(´д｀;)" "( ´д`;)" "( ;´д`)" "(;´д` )"]
                         ["(」・ω・)」" "(／・ω・)／" "(」・ω・)」" "(／・ω・)／"
                          "(」・ω・)」" "(／・ω・)／" "(」・ω・)」" "＼(・ω・)／"]
                         ["(＞ワ＜三　　　)" "(　＞ワ三＜　　)"
                          "(　　＞三ワ＜　)" "(　　　三＞ワ＜)"
                          "(　　＞三ワ＜　)" "(　＞ワ三＜　　)"]])


;;; Variables

(defvar nyan-xpm-support (image-type-available-p 'xpm))
(defvar nyan-old-car-mode-line-position nil)
(defvar nyan-rainbow-image nil)
(defvar nyan-outerspace-image nil)
(defvar nyan-animation-each-frames nil)
(defvar nyan-cat-image nil)
(defvar nyan-current-frame 0)
(defvar nyan-animation-timer nil "Animation timer.")
(defvar nyan-music-process nil "Mplayer needs to be installed for that.")

;; Functions

(defun nyan--is-animating-p ()
  "T if animating, NIL otherwise."
  (timerp nyan-animation-timer))


(defun nyan-set-flavor (flavor)
  "Set current nyan FLAVOR."
  (setq nyan-rainbow-image (concat nyan-directory "img/" flavor "/rainbow.xpm"))
  (setq nyan-outerspace-image (concat nyan-directory "img/" flavor "/outerspace.xpm"))
  (setq nyan-animation-each-frames (if nyan-xpm-support
                                       (mapcar (lambda (id)
                                                 (create-image (concat nyan-directory (format "img/%s/nyan-frame-%d.xpm" flavor id))
                                                               'xpm nil :ascent 'center))
                                               (number-sequence 1 (length (directory-files
                                                                           (concat nyan-directory (format "img/%s" flavor)) nil "nyan-frame-[0-9]+.xpm")))
                                               )))
  (setq nyan-cat-image (if nyan-xpm-support
                           (create-image (concat nyan-directory "img/" flavor "/nyan.xpm") 'xpm nil :ascent 'center))))


(defun nyan-swich-anim-frame ()
  "Switch next frame."
  (setq nyan-current-frame (% (+ 1 nyan-current-frame) (length nyan-animation-each-frames)))
  (force-mode-line-update))


(defun nyan-get-anim-frame ()
  "Get current frame."
  (if (nyan--is-animating-p)
      (nth nyan-current-frame nyan-animation-each-frames)
    nyan-cat-image))


(defun nyan-wavy-rainbow-ascent (number)
  "Make display ascent by NUMBER."
  (if (nyan--is-animating-p)
      (if (> 2
             (% (+ number nyan-current-frame) 4))
          80 'center)
    (if (zerop (logand number 1)) 80 'center)))


(defun nyan-number-of-rainbows ()
  "Coloured nyan position."
  (round (/ (* (round (* 100
                         (/ (- (float (point))
                               (float (point-min)))
                            (float (point-max)))))
               (- nyan-bar-length nyan-cat-size))
            100)))


(defun nyan-catface ()
  "Select string of face."
  (aref nyan-cat-face nyan-cat-face-number))


(defun nyan-catface-index ()
  "Char nyan position."
  (min (round (/ (* (round (* 100
                              (/ (- (float (point))
                                    (float (point-min)))
                                 (float (point-max)))))
                    (length (nyan-catface)))
                 100))
       (- (length (nyan-catface)) 1)))


(defun nyan-scroll-buffer (percentage buffer)
  "Move point `BUFFER' to `PERCENTAGE' percent in the buffer."
  (interactive)
  (with-current-buffer buffer
    (goto-char (floor (* percentage (point-max))))))


(defun nyan-add-scroll-handler (string percentage buffer)
  "Propertize `STRING' to scroll `BUFFER' to `PERCENTAGE' on click."
  (let ((percentage percentage)
        (buffer buffer))
    (propertize string
                'keymap
                `(keymap (mode-line keymap
                                    (down-mouse-1 . ,(lambda ()
                                                       (interactive)
                                                       (nyan-scroll-buffer percentage buffer))))))))

;; (defun nyan-create-rainbow ()
;;   "Make rainbow."
;;   (dotimes (number rainbows)
;;     (setq rainbow-string (concat rainbow-string
;;                                  (nyan-add-scroll-handler
;;                                   (if nyan-xpm-support
;;                                       (propertize "|"
;;                                                   'display (create-image nyan-rainbow-image 'xpm nil :ascent (or (and nyan-wavy-trail
;;                                                                                                                       (nyan-wavy-rainbow-ascent number))
;;                                                                                                                  (if (nyan--is-animating-p) 95 'center))))
;;                                     "|")
;;                                   (/ (float number) nyan-bar-length) buffer))))

;;   )


(defun nyan-create ()
  "Return the Nyan Cat indicator to be inserted into mode line."
  (if (< (window-width) nyan-minimum-window-width)
      ""                                ; disabled for too small windows
    (let* ((rainbows (nyan-number-of-rainbows))
           (outerspaces (- nyan-bar-length rainbows nyan-cat-size))
           (rainbow-string "")
           (nyancat-string (propertize
                            (aref (nyan-catface) (nyan-catface-index))
                            'display (nyan-get-anim-frame)))
           (outerspace-string "")
           (buffer (current-buffer)))
      (dotimes (number rainbows)
        (setq rainbow-string (concat rainbow-string
                                     (nyan-add-scroll-handler
                                      (if nyan-xpm-support
                                          (propertize "|"
                                                      'display (create-image nyan-rainbow-image 'xpm nil :ascent (or (and nyan-wavy-trail
                                                                                                                          (nyan-wavy-rainbow-ascent number))
                                                                                                                     'center)))
                                        "|")
                                      (/ (float number) nyan-bar-length) buffer))))
      (dotimes (number outerspaces)
        (setq outerspace-string (concat outerspace-string
                                        (nyan-add-scroll-handler
                                         (if nyan-xpm-support
                                             (propertize "-"
                                                         'display (create-image nyan-outerspace-image 'xpm nil :ascent 'center))
                                           "-")
                                         (/ (float (+ rainbows nyan-cat-size number)) nyan-bar-length) buffer))))
      ;; Compute Nyan Cat string.
      (propertize (concat rainbow-string
                          nyancat-string
                          outerspace-string)
                  'help-echo nyan-modeline-help-string))))

;;; Interactives

;;;###autoload
(defun nyan-toggle-wavy-trail ()
  "Toggle the trail to look more like the original Nyan Cat animation."
  (interactive)
  (setq nyan-wavy-trail (not nyan-wavy-trail)))


;;;###autoload
(defun nyan-start-animation ()
  "Nyan start animation."
  (interactive)
  (unless (nyan--is-animating-p)
    (setq nyan-animation-timer (run-at-time "1 sec"
                                            (/ 1 (float nyan-animation-frames))
                                            'nyan-swich-anim-frame))))


;;;###autoload
(defun nyan-stop-animation ()
  "Nyan stop animation."
  (interactive)
  (when (nyan--is-animating-p)
    (cancel-timer nyan-animation-timer)
    (setq nyan-animation-timer nil)))

;;; Music handling.

;;;###autoload
(defun nyan-start-music ()
  "Nyan start music."
  (interactive)
  (unless nyan-music-process
    (setq nyan-music-process (start-process-shell-command "nyan-music"
                                                          "nyan-music"
                                                          (concat "mplayer " nyan-music " -loop 0")))))


;;;###autoload
(defun nyan-stop-music ()
  "Nyan stop music."
  (interactive)
  (when nyan-music-process
    (delete-process nyan-music-process)
    (setq nyan-music-process nil)))

;; Select nyan flavor

;;;###autoload
(defun nyan-pick-flavor ()
  "Pick a nyan flavor."
  (interactive)
  (let ((str (completing-read (format "Current flavor is <%s>. Please choose: " (symbol-name nyan-cat-flavor))
                              nyan-flavor-list
                              nil
                              t
                              nil
                              nil
                              (symbol-name nyan-cat-flavor)
                              )))
    (setq nyan-cat-flavor (intern str))
    (nyan-set-flavor str)))


;;;###autoload
(define-minor-mode nyan-mode
  "Use NyanCat to show buffer size and position in mode-line.
You can customize this minor mode, see option `nyan-mode'.

Note: If you turn this mode on then you probably want to turn off
option `scroll-bar-mode'."
  :global t
  :group 'nyan
  ;; FIXME: That doesn't smell right; might still get duplicate nyan cats and other mode-line disruptions.  -- Jacek Złydach, 2020-05-26
  (cond (nyan-mode
         (nyan-set-flavor (symbol-name nyan-cat-flavor))
         
         (unless nyan-old-car-mode-line-position
           (setq nyan-old-car-mode-line-position (car mode-line-position)))
         (setcar mode-line-position '(:eval (list (nyan-create))))
         ;; NOTE Redundant, but intended to, in the future, prevent the custom variable from starting the animation timer even if nyan mode isn't active. -- Jacek Złydach, 2020-05-26
         (when nyan-animate-nyancat
           (nyan-start-animation)))
        ((not nyan-mode)
         (nyan-stop-animation)          ; In case there was an animation going on.
         (setcar mode-line-position nyan-old-car-mode-line-position)
         (setq nyan-old-car-mode-line-position nil))))


(provide 'nyan-mode)

;;; nyan-mode.el ends here

;; (count-screen-lines
;;    (point-min)
;;    (save-excursion (beginning-of-visual-line) (point)))
;; (string-to-number (format-mode-line "%l"))
;; (line-number-at-pos (point-max))
;; (count-lines (point-min) (point-max))

;; (defvar my-mode-line-buffer-line-count nil)
;; (make-variable-buffer-local 'my-mode-line-buffer-line-count)

;; (setq-default mode-line-format
;;               '("  " mode-line-modified
;;                 (list 'line-number-mode "  ")
;;                 (:eval (when line-number-mode
;;                          (let ((str "L%l"))
;;                            (when (and (not (buffer-modified-p)) my-mode-line-buffer-line-count)
;;                              (setq str (concat str "/" my-mode-line-buffer-line-count)))
;;                            str)))
;;                 "  %p"
;;                 (list 'column-number-mode "  C%c")
;;                 "  " mode-line-buffer-identification
;;                 "  " mode-line-modes))

;; (defun my-mode-line-count-lines ()
;;   (setq my-mode-line-buffer-line-count (int-to-string (count-lines (point-min) (point-max)))))

;; (add-hook 'find-file-hook 'my-mode-line-count-lines)
;; (add-hook 'after-save-hook 'my-mode-line-count-lines)
;; (add-hook 'after-revert-hook 'my-mode-line-count-lines)
;; (add-hook 'dired-after-readin-hook 'my-mode-line-count-lines)
