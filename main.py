import os
import re
import threading
import time
import base64
import io
import random
import requests
from PIL import Image as PILImage
import numpy as np
import cv2
import onnxruntime as ort
import torchvision.transforms as transforms

from bidi.algorithm import get_display
import arabic_reshaper

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.image import Image
from kivy.uix.progressbar import ProgressBar
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.clock import Clock
from kivy.core.text import LabelBase
from kivy.core.window import Window
from kivy.graphics.texture import Texture

# --------------------------------------------------
# مسارات الأصول (assets)
# --------------------------------------------------
BASE_DIR = os.path.dirname(__file__)
ASSETS_DIR = os.path.join(BASE_DIR, 'assets')
ONNX_MODEL_PATH = os.path.join(ASSETS_DIR, 'holako bag.onnx')
FONT_PATH       = os.path.join(ASSETS_DIR, 'NotoNaskhArabic-Regular.ttf')

# --------------------------------------------------
# Register Arabic font (supports Arabic shaping)
# --------------------------------------------------
LabelBase.register(name='Arabic', fn_regular=FONT_PATH)

# --------------------------------------------------
# Helper: reshape only Arabic, leave English/digits intact
# --------------------------------------------------
def ar(text):
    if re.search(r'[\u0600-\u06FF]', text):
        reshaped = arabic_reshaper.reshape(text)
        return get_display(reshaped)
    else:
        return text

# --------------------------------------------------
# Constants: include digits + lowercase + uppercase English
# --------------------------------------------------
CHARSET = '0123456789abcdefghijklmnopqrstuvwxyz'
CHAR2IDX = {c: i for i, c in enumerate(CHARSET)}
IDX2CHAR = {i: c for c, i in CHAR2IDX.items()}
NUM_CLASSES = len(CHARSET)
NUM_POS = 5

# --------------------------------------------------
# Preprocessing transform
# --------------------------------------------------
def preprocess_for_model():
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.Grayscale(num_output_channels=3),
        transforms.ToTensor(),
        transforms.Normalize([0.5, 0.5, 0.5], [0.5, 0.5, 0.5]),
    ])

# --------------------------------------------------
# Main UI widget
# --------------------------------------------------
class MainWidget(BoxLayout):
    def __init__(self, **kwargs):
        super(MainWidget, self).__init__(orientation='vertical', spacing=10, padding=10, **kwargs)
        self.app = App.get_running_app()
        self.accounts = {}
        self.current_captcha = None

        # Notification Label
        self.notification = Label(
            text='', font_name='Arabic', font_size='16sp', size_hint=(1, None), height=30,
            halign='right', text_size=(Window.width-20, None)
        )
        self.add_widget(self.notification)

        # Add Account Button
        btn_layout = BoxLayout(size_hint=(1, None), height=40)
        btn_add = Button(
            text=ar('إضافة حساب'), font_name='Arabic', size_hint=(None, None), size=(200, 40),
            on_release=self.on_add_account
        )
        btn_layout.add_widget(btn_add)
        self.add_widget(btn_layout)

        # Accounts ScrollView
        self.scroll = ScrollView(size_hint=(1, 1))
        self.accounts_box = BoxLayout(orientation='vertical', spacing=10, size_hint_y=None)
        self.accounts_box.bind(minimum_height=self.accounts_box.setter('height'))
        self.scroll.add_widget(self.accounts_box)
        self.add_widget(self.scroll)

        # Captcha display area
        self.captcha_img = Image(size_hint=(1, 0.5))
        self.add_widget(self.captcha_img)

        # Speed Label
        self.speed_label = Label(
            text=ar('المعالجة: 0 ملليثانية | التنبؤ: 0 ملليثانية'), font_name='Arabic', font_size='14sp',
            size_hint=(1, None), height=30, halign='right', text_size=(Window.width-20, None)
        )
        self.add_widget(self.speed_label)

        # Load ONNX model
        if not os.path.exists(ONNX_MODEL_PATH):
            self.show_error(ar(f"ملف النموذج غير موجود في: {ONNX_MODEL_PATH}"))
            return
        try:
            self.session = ort.InferenceSession(ONNX_MODEL_PATH, providers=['CPUExecutionProvider'])
        except Exception as e:
            self.show_error(ar(f"فشل تحميل النموذج: {e}"))
            return

    def show_notification(self, msg, color=(1,1,1,1)):
        self.notification.color = color
        self.notification.text = msg
        print(msg)

    def show_error(self, msg):
        popup = Popup(
            title=ar('خطأ'),
            content=Label(text=msg, font_name='Arabic', halign='right', text_size=(Window.width*0.7, None)),
            size_hint=(0.8, 0.4)
        )
        popup.open()

    def generate_user_agent(self):
        ua_list = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Mobile Safari/537.36",
            "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
        ]
        return random.choice(ua_list)

    def create_session(self):
        headers = {
            "User-Agent": self.generate_user_agent(),
            "Host": "api.ecsc.gov.sy:8443",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "ar,en-US;q=0.7,en;q=0.3",
            "Referer": "https://ecsc.gov.sy/login",
            "Content-Type": "application/json",
            "Source": "WEB",
            "Origin": "https://ecsc.gov.sy",
            "Connection": "keep-alive",
        }
        session = requests.Session()
        session.headers.update(headers)
        return session

    def on_add_account(self, instance):
        content = BoxLayout(orientation='vertical', spacing=10, padding=10)
        user_input = TextInput(hint_text=ar('اسم المستخدم'), multiline=False, font_name='Arabic')
        pwd_input = TextInput(hint_text=ar('كلمة المرور'), multiline=False, password=True, font_name='Arabic')
        btn_login = Button(text=ar('تسجيل الدخول'), size_hint=(1, None), height=40, font_name='Arabic')
        content.add_widget(user_input)
        content.add_widget(pwd_input)
        content.add_widget(btn_login)
        popup = Popup(title=ar('إضافة حساب'), content=content, size_hint=(0.8, 0.5))

        def do_login(btn):
            user, pwd = user_input.text.strip(), pwd_input.text.strip()
            if user and pwd:
                popup.dismiss()
                self.process_login(user, pwd)

        btn_login.bind(on_release=do_login)
        popup.open()

    def process_login(self, user, pwd):
        session = self.create_session()
        def login_thread():
            start = time.time()
            ok = self.login(user, pwd, session)
            elapsed = time.time() - start
            if ok:
                Clock.schedule_once(lambda dt: self.show_notification(ar(f"تم تسجيل الدخول: {user} في {elapsed:.2f} ثانية"), (0,1,0,1)))
                self.accounts[user] = {'password': pwd, 'session': session}
                proc = self.fetch_process_ids(session)
                Clock.schedule_once(lambda dt: self.add_account_ui(user, proc))
            else:
                Clock.schedule_once(lambda dt: self.show_notification(ar("فشل تسجيل الدخول"), (1,0,0,1)))
        threading.Thread(target=login_thread, daemon=True).start()

    def login(self, username, password, session, retries=3):
        url = "https://api.ecsc.gov.sy:8443/secure/auth/login"
        payload = {"username": username, "password": password}
        for _ in range(retries):
            try:
                r = session.post(url, json=payload, verify=False)
                if r.status_code == 200:
                    return True
                return False
            except:
                return False
        return False

    def fetch_process_ids(self, session):
        try:
            url = "https://api.ecsc.gov.sy:8443/dbm/db/execute"
            payload = {"ALIAS": "OPkUVkYsyq", "P_USERNAME": "WebSite", "P_PAGE_INDEX": 0, "P_PAGE_SIZE": 100}
            headers = {"Content-Type": "application/json", "Alias": "OPkUVkYsyq", "Referer": "https://ecsc.gov.sy/requests", "Origin": "https://ecsc.gov.sy"}
            r = session.post(url, json=payload, headers=headers, verify=False)
            if r.status_code == 200:
                return r.json().get("P_RESULT", [])
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(ar(f"خطأ في جلب العمليات: {e}"), (1,0,0,1)))
        return []

    def add_account_ui(self, user, processes):
        acc_box = BoxLayout(orientation='vertical', size_hint_y=None, height=len(processes)*60+40, padding=5, spacing=5)
        acc_box.add_widget(Label(text=ar(f"الحساب: {user}"), font_name='Arabic', size_hint_y=None, height=30, halign='right', text_size=(Window.width-20, None)))
        for proc in processes:
            pid = proc.get("PROCESS_ID")
            name = proc.get("ZCENTER_NAME", "غير معروف")
            row = BoxLayout(orientation='horizontal', size_hint_y=None, height=40, spacing=5)
            btn = Button(text=ar(name), size_hint_x=None, width=200, font_name='Arabic')
            prog = ProgressBar(max=1, value=0)
            btn.bind(on_release=lambda inst, u=user, p=pid, pb=prog: threading.Thread(target=self.handle_captcha, args=(u, p, pb), daemon=True).start())
            row.add_widget(btn)
            row.add_widget(prog)
            acc_box.add_widget(row)
        self.accounts_box.add_widget(acc_box)

    def handle_captcha(self, user, pid, prog):
        Clock.schedule_once(lambda dt: prog.setter('value')(prog, 0))
        data = self.get_captcha(self.accounts[user]['session'], pid, user)
        if data:
            self.current_captcha = (user, pid)
            Clock.schedule_once(lambda dt: self.show_captcha(data, prog))

    def get_captcha(self, session, pid, user):
        url = f"https://api.ecsc.gov.sy:8443/captcha/get/{pid}"
        try:
            while True:
                r = session.get(url, verify=False)
                if r.status_code == 200:
                    return r.json().get('file')
                elif r.status_code == 429:
                    time.sleep(0.1)
                elif r.status_code in (401,403):
                    if not self.login(user, self.accounts[user]['password'], session):
                        return None
                else:
                    Clock.schedule_once(lambda dt: self.show_notification(ar(f"خطأ في الخادم: {r.status_code}"), (1,0,0,1)))
                    return None
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(ar(f"خطأ في جلب الكابتشا: {e}"), (1,0,0,1)))
        return None

    def predict_captcha(self, pil_img):
        tf = preprocess_for_model()
        img = pil_img.convert("RGB")
        start_pre = time.time()
        x = tf(img).unsqueeze(0).numpy().astype(np.float32)
        end_pre = time.time()

        start_pred = time.time()
        ort_outs = self.session.run(None, {'input': x})[0]
        end_pred = time.time()

        ort_outs = ort_outs.reshape(1, NUM_POS, NUM_CLASSES)
        idxs = np.argmax(ort_outs, axis=2)[0]
        pred = ''.join(IDX2CHAR[i] for i in idxs)

        pre_ms = (end_pre - start_pre) * 1000
        pred_ms = (end_pred - start_pred) * 1000
        return pred, pre_ms, pred_ms

    def show_captcha(self, b64data, prog):
        b64 = b64data.split(',')[1] if ',' in b64data else b64data
        raw = base64.b64decode(b64)
        pil = PILImage.open(io.BytesIO(raw))

        frames = []
        try:
            while True:
                frames.append(np.array(pil.convert("RGB")))
                pil.seek(pil.tell() + 1)
        except EOFError:
            pass
        stack = np.stack(frames).astype(np.uint8)
        bg = np.median(stack, axis=0).astype(np.uint8)
        gray = cv2.cvtColor(bg, cv2.COLOR_RGB2GRAY)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        enh = clahe.apply(gray)
        _, binary = cv2.threshold(enh, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        proc_img = PILImage.fromarray(binary)

        pred, pre_ms, pred_ms = self.predict_captcha(proc_img)
        notification_text = ar("الناتج المتوقع للكابتشا: ") + pred
        Clock.schedule_once(lambda dt: self.show_notification(notification_text, (0,0,1,1)))
        self.speed_label.text = ar(f"المعالجة: {pre_ms:.2f} ملليثانية | التنبؤ: {pred_ms:.2f} ملليثانية")
        self.submit_captcha(pred)

        self.captcha_img.texture = self.pil_to_texture(proc_img)
        Clock.schedule_once(lambda dt: prog.setter('value')(prog, 1))

    def pil_to_texture(self, pil_img):
        arr = np.array(pil_img)
        h, w = arr.shape
        buf = arr.tobytes()
        texture = Texture.create(size=(w, h), colorfmt='luminance')
        texture.blit_buffer(buf, colorfmt='luminance', bufferfmt='ubyte')
        return texture

    def submit_captcha(self, solution):
        user, pid = self.current_captcha
        session = self.accounts[user]['session']
        url = f"https://api.ecsc.gov.sy:8443/rs/reserve?id={pid}&captcha={solution}"
        try:
            r = session.get(url, verify=False)
            color = (0,1,0,1) if r.status_code == 200 else (1,0,0,1)
            Clock.schedule_once(lambda dt: self.show_notification(ar(f"تم التثبيت: {r.text}"), color))
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(ar(f"خطأ في الإرسال: {e}"), (1,0,0,1)))

class CaptchaApp(App):
    def build(self):
        Window.clearcolor = (1,1,1,1)
        return MainWidget()


if __name__ == '__main__':
    CaptchaApp().run()
