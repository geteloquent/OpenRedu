class Subject < ActiveRecord::Base


  # PLUGINS
  acts_as_taggable
  ajaxful_rateable :stars => 5
  has_attached_file :avatar, {
    :styles => { :thumb => "100x100>", :nano => "24x24>",
                 :default_url => "/images/:class/missing_pic.jpg"}
  }


  #validations
  validates_presence_of :title, :if => lambda {|s| s.current_step == "subject"}
  validates_presence_of :description, :if => lambda {|s| s.current_step == "subject"}
  # validates_presence_of :simple_category

  #associations
  has_and_belongs_to_many :audiences
  has_many :course_subjects, :dependent => :destroy
  has_many :enrollments, :dependent => :destroy
  belongs_to :owner, :class_name => "User" , :foreign_key => "user_id"
  belongs_to :school
  belongs_to :simple_category
  has_many :statuses, :as => :statusable
  has_many :students, :through => :enrollments, :source => :user, :conditions => [ "enrollments.role_id = ?", 7 ]
  has_many :teachers, :through => :enrollments, :source => :user, :conditions => [ "enrollments.role_id = ?", 6 ]



  # METODOS DO WIZARD
  attr_writer :current_step


  def to_param #friendly url
    "#{id}-#{title.parameterize}"
  end

  def permalink
    APP_URL + "/subjects/"+ self.id.to_s+"-"+self.title.parameterize
  end


  def recent_activity(limit = 0, offset = 20) #TODO colocar esse metodo em status passando apenas o objeto
    page = limit.to_i/10 + 1
    self.statuses.descend_by_created_at.paginate(:per_page => offset, :page =>page)
  end


  def current_step
    @current_step || steps.first
  end

  def steps
    %w[subject course publication]
  end

  def next_step
    self.current_step = steps[steps.index(current_step)+1]
  end

  def previous_step
    self.current_step = steps[steps.index(current_step)-1]
  end

  def first_step?
    current_step == steps.first
  end

  def last_step?
    current_step == steps.last
  end

  def all_valid?
    steps.all? do |step|
      self.current_step = step
      valid?
    end
  end



  def create_course_subject_type_course aulas, subject_id, current_user

    aulas.each do |aula|

      course = current_user.courses.find(aula) #find the course by id
      clone_course = course.clone #clone it
      clone_course.is_clone = true
      clone_course.save#and save it
      cs = CourseSubject.new
      cs.subject_id = subject_id
      cs.courseable_id = clone_course.id
      cs.courseable_type = "Course"
      cs.save
    end

  end


  def update_course_subject_type_course aulas, subject_id, current_user

    aulas_futuras =   aulas.nil? ? Array.new : aulas.map{|a| a.to_i}  #aulas selecionadas na tela, há um operador ternário
    #caso o usuario deschecar todas aulas ou nao houver aula associoda ao curso

    subject = current_user.subjects.find(subject_id) # meu current curso

    aulas_ids = subject.aulas.map{|a| a.id} # aulas relaciondas com o curso
    deleted_ids =  aulas_ids - aulas_futuras # aulas q serao deletadas
    inserted_ids = aulas_futuras - aulas_ids #aulas q serao inseridas

    CourseSubject.destroy_all(:courseable_id => deleted_ids) unless deleted_ids.empty?#segurança ok, pois o array deleted_ids eh criado a partir do current_user


    unless inserted_ids.empty?
      inserted_ids.each do |aula|

        course = current_user.courses.find(aula) #find the course by id
        clone_course = course.clone #clone it
        clone_course.is_clone = true
        clone_course.save#and save it
        cs = CourseSubject.new
        cs.subject_id = subject_id
        cs.courseable_id = clone_course.id
        cs.courseable_type = "Course"
        cs.save
      end
    end

  end

  def update_course_subject_type_exam exams, subject_id, current_user

    exams_futuras =   exams.nil? ? Array.new : exams.map{|a| a.to_i}  #aulas selecionadas na tela, há um operador ternário
    #caso o usuario deschecar todas aulas ou nao houver aula associoda ao curso

    subject = current_user.subjects.find(subject_id) # meu current curso

    exames_ids = subject.exames.map{|a| a.id} # aulas relaciondas com o curso
    deleted_ids =  exames_ids  - exams_futuras # aulas q serao deletadas
    inserted_ids = exams_futuras-  exames_ids #aulas q serao inseridas

    CourseSubject.destroy_all(:courseable_id => deleted_ids) unless deleted_ids.empty?#segurança ok, pois o array deleted_ids eh criado a partir do current_user


    unless inserted_ids.empty?
      inserted_ids.each do |exame_id|

        exame = current_user.exams.find(exame_id) #find the course by id
        clone_exame = exame.clone #clone it
        clone_exame.is_clone = true
        clone_exame.save#and save it
        cs = CourseSubject.new
        cs.subject_id = subject_id
        cs.courseable_id = clone_exame.id
        cs.courseable_type = "Exam"
        cs.save
      end
    end

  end


  def create_course_subject_type_exam exams, subject_id, current_user

    exams.each do |exam_id|
      exame = current_user.exams.find(exam_id) #find exame by id
      clone_exame = exame.clone #clone it
      clone_exame.is_clone = true
      clone_exame.save#and save it
      cs = CourseSubject.new
      cs.subject_id = subject_id
      cs.courseable_id = exam_id
      cs.courseable_type = "Exam"
      cs.save
    end

  end

  def aulas
    self.course_subjects.select{|cs| cs.courseable_type.eql?("Course")}.map{|a| a.courseable}
  end

  def exames
    self.course_subjects.select{|cs| cs.courseable_type.eql?("Exam")}.map{|e| e.courseable}
  end

  def students
    self.enrollments.map{|e| e.user}
  end


end
