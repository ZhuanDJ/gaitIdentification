package kr.ac.kaist.team2.gaitcollection;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Parcelable;
import android.util.Log;
import android.util.SparseBooleanArray;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.ToggleButton;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

public class MainActivity extends Activity implements SensorEventListener, OnClickListener , View.OnTouchListener {

    // 가속도 센서값을 출력하기 위한 TextView
    TextView tvAccelX = null;
    TextView tvAccelY = null;
    TextView tvAccelZ = null;
    // 자이로 센서값을 출력하기 위한 TextView
    TextView tvGyroX = null;
    TextView tvGyroY = null;
    TextView tvGyroZ = null;
    // 중력 센서값을 출력하기 위한 TextView
    TextView tvGraviX = null;
    TextView tvGraviY = null;
    TextView tvGraviZ = null;

    ListView fileListView = null;
    ArrayAdapter fileArrayAdapter = null;

    ScrollView wrappingScrollView = null;

    //기록 버튼
    ToggleButton recordButton = null;
    Boolean isRecording = false;

    Button keyboardButton = null;

    Button sensorDelayButton = null;


    Button sendEmailButton = null;
    Button deleteSelectedButton = null;
    EditText tickEditText = null;
    EditText toEmailEditTextBox = null;


    // 센서 관리자
    SensorManager sm = null;
    // 가속도 센서
    Sensor accSensor = null;
    // 자이로센서 센서
    Sensor gyroSensor = null;
    // 중력 센서
    Sensor graviSensor = null;

    File recordingFile = null;
    FileOutputStream fos = null;
    String recordingFileName = null;
    PrintWriter writer = null;


    Thread recordThread = null;

    int tick = 500;
    String rootPath = null;
    String gaitDataPath = "/gaitData/";
    String gaitDataFullPath = null;

    int listItemSize = 150;
    int sensorDelay = SensorManager.SENSOR_DELAY_FASTEST;
    int tempDelay = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        tvAccelX = (TextView) findViewById(R.id.tvAccelX);
        tvAccelY = (TextView) findViewById(R.id.tvAccelY);
        tvAccelZ = (TextView) findViewById(R.id.tvAccelZ);
        tvGyroX = (TextView) findViewById(R.id.tvGyroX);
        tvGyroY = (TextView) findViewById(R.id.tvGyroY);
        tvGyroZ = (TextView) findViewById(R.id.tvGyroZ);
        tvGraviX = (TextView) findViewById(R.id.tvGravX);
        tvGraviY = (TextView) findViewById(R.id.tvGravY);
        tvGraviZ = (TextView) findViewById(R.id.tvGravZ);

        recordButton = (ToggleButton) findViewById(R.id.recordButton);
        sendEmailButton = (Button) findViewById(R.id.sendEmailButton);
        deleteSelectedButton = (Button) findViewById(R.id.deleteSelectedButton);

        keyboardButton = (Button) findViewById(R.id.keyboardButton);

        sensorDelayButton = (Button) findViewById(R.id.sensorDelayButton);

        toEmailEditTextBox = (EditText) findViewById(R.id.toEmailText);

        tickEditText = (EditText) findViewById(R.id.tickEditText);
        tickEditText.setText(String.valueOf(tick));

        getRootDirectory();

        fileListView = (ListView) findViewById(R.id.fileListView);
        setFileListViewAdapter();



        wrappingScrollView = (ScrollView) findViewById(R.id.wrappingScrollView);


        // SensorManager 인스턴스를 가져옴
        sm = (SensorManager) getSystemService(SENSOR_SERVICE);
        // 가속도 센서
        accSensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        // 자이로센서 센서
        gyroSensor = sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        // 중력 센서
        graviSensor = sm.getDefaultSensor(Sensor.TYPE_GRAVITY);
    }

    @Override
    public void onResume() {
        super.onResume();

        setSensorListener();
        setSensorDelayButtonText();

        recordButton.setOnClickListener(this);
        fileListView.setOnTouchListener(this);
        fileListView.setChoiceMode(ListView.CHOICE_MODE_MULTIPLE);

        sendEmailButton.setOnClickListener(this);
        deleteSelectedButton.setOnClickListener(this);
        keyboardButton.setOnClickListener(this);
        sensorDelayButton.setOnClickListener(this);

    }

    private void setSensorDelayButtonText(){
        switch(sensorDelay){
            case SensorManager.SENSOR_DELAY_UI:
                sensorDelayButton.setText("SENSOR_DELAY_UI");
                break;
            case SensorManager.SENSOR_DELAY_NORMAL:
                sensorDelayButton.setText("SENSOR_DELAY_NORMAL");
                break;
            case SensorManager.SENSOR_DELAY_GAME:
                sensorDelayButton.setText("SENSOR_DELAY_GAME");
                break;

            case SensorManager.SENSOR_DELAY_FASTEST:
            default:
                sensorDelayButton.setText("SENSOR_DELAY_FASTEST");
                break;
        }
    }

    private void setSensorListener() {
        sm.unregisterListener(this, accSensor);
        sm.unregisterListener(this, gyroSensor);
        sm.unregisterListener(this, graviSensor);

        // 가속도 센서 리스너 오브젝트를 등록
        sm.registerListener(this, accSensor, sensorDelay);
        // 자이로 센서 리스너 오브젝트를 등록
        sm.registerListener(this, gyroSensor, sensorDelay);
        // 중력 센서 리스너 오브젝트를 등록
        sm.registerListener(this, graviSensor, sensorDelay);
    }

    @Override
    public void onPause() {
        super.onPause();
        // 센서에서 이벤트 리스너 분리
        sm.unregisterListener(this);
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        switch (event.sensor.getType()) {
            case Sensor.TYPE_ACCELEROMETER:
                tvAccelX.setText(String.valueOf(event.values[0]));
                tvAccelY.setText(String.valueOf(event.values[1]));
                tvAccelZ.setText(String.valueOf(event.values[2]));
                break;
            case Sensor.TYPE_GYROSCOPE:
                tvGyroX.setText(String.valueOf(event.values[0] * 1000));
                tvGyroY.setText(String.valueOf(event.values[1] * 1000));
                tvGyroZ.setText(String.valueOf(event.values[2] * 1000));
                break;
            case Sensor.TYPE_GRAVITY:
                tvGraviX.setText(String.valueOf(event.values[0]));
                tvGraviY.setText(String.valueOf(event.values[1]));
                tvGraviZ.setText(String.valueOf(event.values[2]));

        }
    }

    @Override
    public void onClick(View v) {
        switch(v.getId()) {
            case R.id.recordButton:     //기록 토글버튼
                isRecording = (isRecording == true ? false : true);
                if (isRecording == true) {
                    long nowMills = System.currentTimeMillis();
                    Date date = new Date(nowMills);
                    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
                    recordingFileName = "gaitdata_" + simpleDateFormat.format(date).toString() + ".txt";

                    try{
                        //파일 오픈
                        fos = new FileOutputStream(new File(gaitDataFullPath, recordingFileName));
                        //openFileOutput(new File(gaitDataFullPath, recordingFileName));
                        String topLine = new String("Accelerometer x y z\tGyroscope x y z\tGravity x y z");
                        writer= new PrintWriter(fos);
                        writer.println(topLine);
                    } catch(Exception e){
                        e.printStackTrace();
                    }
                    tick = Integer.parseInt(tickEditText.getText().toString());

                    //레코딩을 위한 thread 생성
                    recordThread = new Thread(new Runnable(){
                        public void run(){
                            while(isRecording == true){
                                try{
                                    String tvAccelXVal = tvAccelX.getText().toString();
                                    String tvAccelYVal = tvAccelY.getText().toString();
                                    String tvAccelZVal = tvAccelZ.getText().toString();
                                    String tvGyroXVal = tvGyroX.getText().toString();
                                    String tvGyroYVal = tvGyroY.getText().toString();
                                    String tvGyroZVal = tvGyroZ.getText().toString();
                                    String tvGraviXVal = tvGraviX.getText().toString();
                                    String tvGraviYVal = tvGraviY.getText().toString();
                                    String tvGraviZVal = tvGraviZ.getText().toString();


                                    String line = tvAccelXVal + " " + tvAccelYVal + " " + tvAccelZVal + " " + tvGyroXVal + " "+ tvGyroYVal + " "+ tvGyroZVal + " " + tvGraviXVal + " "+ tvGraviYVal + " "+ tvGraviZVal;
                                    writer.println(line);

                                    Thread.sleep(tick);
                                }   catch(Exception e){
                                    e.printStackTrace();
                                }

                            }
                            try {
                                writer.close();
                            } catch(Exception e){
                                e.printStackTrace();
                            }
                        }
                    });

                    recordThread.start();
                }
                else {
                    setFileListViewAdapter();
                }

                break;
            case R.id.deleteSelectedButton:     //선택파일 삭제 버튼
                SparseBooleanArray filePosArray = fileListView.getCheckedItemPositions();
                for(int i = 0; i < filePosArray.size(); i++) {
                    int pos = filePosArray.keyAt(i);

                    String filename = gaitDataFullPath + fileListView.getItemAtPosition(pos).toString();
                    File file = new File(filename);
                    if (file.exists() == true)
                        file.delete();
                }

                setFileListViewAdapter();       //파일리스트 갱신
                break;
            case R.id.sendEmailButton:      //파일 메일로 보내기

                Intent it = new Intent(Intent.ACTION_SEND_MULTIPLE);
                it.setType("plain/text");

                // 수신인 주소 - tos배열의 값을 늘릴 경우 다수의 수신자에게 발송됨
                String[] tos = { toEmailEditTextBox.getText().toString() };
                it.putExtra(Intent.EXTRA_EMAIL, tos);

                long nowMills = System.currentTimeMillis();
                Date date = new Date(nowMills);
                SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
                String subject = "collected_gait data_" + simpleDateFormat.format(date).toString();


                it.putExtra(Intent.EXTRA_SUBJECT, subject);
                it.putExtra(Intent.EXTRA_TEXT, subject);

                ArrayList<Parcelable> uriList = new ArrayList<Parcelable>();
                SparseBooleanArray filePosArray2 = fileListView.getCheckedItemPositions();
                for(int i = 0; i < filePosArray2.size(); i++) {
                    int pos = filePosArray2.keyAt(i);

                    String filename = gaitDataFullPath + fileListView.getItemAtPosition(pos).toString();
                    File file = new File(filename);
                    if (file.exists() == true) {
                        // 파일첨부
                        Uri fileUri = Uri.fromFile(file);
                        uriList.add(fileUri);
                    }

                }
                it.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uriList);

                startActivity(it);

                break;
            case R.id.keyboardButton:
                InputMethodManager imm = (InputMethodManager)getSystemService(INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(toEmailEditTextBox.getWindowToken(),0);
                break;
            case R.id.sensorDelayButton:
                final String items[] = {"SENSOR_DELAY_FASTEST", "SENSOR_DELAY_GAME", "SENSOR_DELAY_NORMAL", "SENSOR_DELAY_UI"};
                AlertDialog.Builder ab = new AlertDialog.Builder(this);

                ab.setTitle("Choose Sensor Delay");
                ab.setSingleChoiceItems(items, 0,
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int whichButton) {
                                // 각 리스트를 선택했을때
                                switch(whichButton)
                                {
                                    case 0:
                                        tempDelay = SensorManager.SENSOR_DELAY_FASTEST;
                                        break;
                                    case 1:
                                        tempDelay = SensorManager.SENSOR_DELAY_GAME;
                                        break;
                                    case 2:
                                        tempDelay = SensorManager.SENSOR_DELAY_NORMAL;
                                        break;
                                    case 3:
                                        tempDelay = SensorManager.SENSOR_DELAY_UI;
                                        break;
                                }
                            }
                        }).setPositiveButton("Ok",
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int whichButton) {

                                sensorDelay = tempDelay;
                                setSensorDelayButtonText();
                                setSensorListener();

                            }
                        }).setNegativeButton("Cancel",
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int whichButton) {
                                // Cancel 버튼 클릭시
                            }
                        });
                ab.show();
                break;
        }

    }


    private String[] getSavedFileTitleList() {
        try {
            FilenameFilter fileFilter = new FilenameFilter()
            {
                public boolean accept(File dir, String name)
                {
                    return name.endsWith("txt");
                } //end accept
            };
            File file = new File(gaitDataFullPath);
            File[] files = file.listFiles(fileFilter);
            String [] titleList = new String [files.length];
            for(int i = 0;i < files.length;i++)
            {
                titleList[i] = files[i].getName();
            }//end for
            return titleList;
        } catch( Exception e ) {
            return null;
        }//end catch()
    }//end getTitleList


    @Override
    public boolean onTouch(View v, MotionEvent event) {
        wrappingScrollView.requestDisallowInterceptTouchEvent(true);
        return false;
    }

    private void setFileListViewAdapter(){
        fileArrayAdapter = new ArrayAdapter(this,android.R.layout.simple_list_item_multiple_choice, getSavedFileTitleList());
        fileListView.setAdapter(fileArrayAdapter);

        //listview 높이조절 대충정함...
        ViewGroup.LayoutParams params = fileListView.getLayoutParams();
        params.height = listItemSize * (fileArrayAdapter.getCount() - 1);
        fileListView.setLayoutParams(params);
        fileListView.requestLayout();
    }

    private void getRootDirectory(){
        String sdcard= Environment.getExternalStorageState();
        if( ! sdcard.equals(Environment.MEDIA_MOUNTED) ) {
            //SD카드 UNMOUNTED

            rootPath = "" + Environment.getRootDirectory().getAbsolutePath(); //내부저장소의 주소를 얻어옴
        } else {
            //SD카드 MOUNT
            rootPath = "" + Environment.getExternalStorageDirectory().getAbsolutePath(); //외부저장소의 주소를 얻어옴
        }

        gaitDataFullPath = rootPath + gaitDataPath;
        File rootCheck = new File(rootPath);
        if( ! rootCheck.exists() ) { //최상위 루트폴더 미 존재시
            rootCheck.mkdirs();
            rootCheck = new File(gaitDataFullPath);
            if( ! rootCheck.exists() ) { //하위 메모저장폴더 미 존재시
                rootCheck.mkdirs();
            }
        }
        else
        {
            rootCheck = new File(gaitDataFullPath);
            if( ! rootCheck.exists() ) { //하위 메모저장폴더 미 존재시
                Boolean flag = rootCheck.mkdirs();
            }
        }
    }
}
